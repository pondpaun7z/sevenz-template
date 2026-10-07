# Record-scoped file storage

Active Storage stores the original binary image or file, not base64 text. All models inheriting from `ApplicationRecord` automatically assign new server-side uploads a key like:

```text
storage/products/42/<random>-photo.png
storage/products/42/<random>-invoice.pdf
```

The random prefix prevents duplicate filenames from overwriting each other. Filenames retain their extensions and are sanitized by Rails. The folder uses the base model's plural name (including for STI) and the saved record ID. The record can be created with its attachments in one save. Existing blobs keep their keys; reattaching or sharing a blob does not move or duplicate it. Existing opaque local keys remain readable in their original sharded folders. Active Storage manages generated previews and variants separately.

## Local files

Run `bin/rails db:migrate` to install the Active Storage tables. Local storage is the default, under `Rails.root/storage`; tests use `tmp/storage`. Original files can be opened directly from the filesystem.

Use normal Rails attachment declarations and uploads:

```ruby
class Product < ApplicationRecord
  has_one_attached :photo
  has_many_attached :documents
end

product = Product.create!(photo: uploaded_file)
product.documents.attach(io: File.open("invoice.pdf"), filename: "invoice.pdf", content_type: "application/pdf")
```

After Rails authorizes access to the record, return an attachment URL in the API's JSON:

```ruby
{
  photo_url: rails_blob_path(product.photo, only_path: true),
  download_url: rails_blob_path(product.photo, disposition: :attachment, only_path: true)
}
```

Vue can use `photo_url` as an image source or link. URLs start with `/storage/blobs/redirect/...`. Rails redirects to a signed `/storage/disk/...` URL for local files or a signed cloud URL. Images open inline; the download URL requests attachment disposition. Rails forces potentially unsafe content types to download.

## Image thumbnails

`image_processing` and `ruby-vips` generate image variants with libvips. The production Docker image already installs libvips. On macOS, install the system library with `brew install vips`; on Debian/Ubuntu, install the `libvips` package.

Every `has_one_attached` and `has_many_attached` declared on an `ApplicationRecord` model includes a named `:thumbnail` variant. It fits within 320×320 pixels, preserves aspect ratio, and does not enlarge smaller images. The original remains unchanged. Models can override `:thumbnail` or declare additional variants using the normal Rails attachment block.

Return both original and thumbnail URLs from the authorized JSON API:

```ruby
photo = product.photo
{
  url: photo.attached? ? rails_blob_path(photo, only_path: true) : nil,
  thumbnail_url: photo.attached? && photo.variable? ? rails_representation_path(photo.variant(:thumbnail), only_path: true) : nil,
  filename: photo.attached? ? photo.filename.to_s : nil
}
```

The `/storage/representations/...` URL generates the thumbnail on its first request and caches it in the original blob's storage service. Subsequent requests reuse the stored variant. For multiple images, use `product.documents.map` and call `attachment.variant(:thumbnail)` for each variable image. Non-image files return `thumbnail_url: nil`; PDF/video previews require their own previewer setup.

The included Vue component loads thumbnails lazily and opens the original when clicked:

```vue
<AttachmentPreview
  v-if="file.url"
  :url="file.url"
  :thumbnail-url="file.thumbnail_url"
  :filename="file.filename"
/>
```

Without a thumbnail URL, the component displays a filename link. Signed thumbnail URLs have the same access considerations as original file URLs.

`/storage` is a route prefix, not a public directory listing. Physical paths such as `/storage/products/42/photo.png` are not public URLs. Signed URLs grant access to anyone possessing the link; protect the API returning them with record-level authentication and authorization. Do not expose the storage directory as static web content.

## Cloud storage

The included S3 adapter also supports S3-compatible providers. Set these environment variables on the Rails server and restart:

```text
ACTIVE_STORAGE_SERVICE=cloud
AWS_REGION=us-east-1
AWS_BUCKET=your-bucket
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
```

For an S3-compatible provider, also set `AWS_ENDPOINT` to its HTTPS endpoint and, if required, `AWS_FORCE_PATH_STYLE=true`. AWS credentials can be omitted when using an IAM role. Keep the bucket private. The object key remains `products/42/<random>-photo.png`; the API's `/storage` URLs redirect to expiring cloud URLs.

Selecting a cloud service applies to new uploads. Existing blobs retain their recorded service; switching the environment variable does not migrate existing files. Cloud direct uploads require the provider's bucket CORS configuration to allow the frontend origin, PUT, and Active Storage's upload headers.

## Direct uploads

Save and authorize the owning record first. In a record-specific API under `/api/v1`, create its direct-upload blob with the declared attachment name:

```ruby
blob = product.create_direct_upload_blob!(:photo,
  filename: params.require(:filename),
  byte_size: params.require(:byte_size),
  checksum: params.require(:checksum),
  content_type: params[:content_type])

render json: blob.as_json.merge(
  signed_id: blob.signed_id,
  direct_upload: {
    url: blob.service_url_for_direct_upload,
    headers: blob.service_headers_for_direct_upload
  }
)
```

The client uploads bytes to `direct_upload.url` using its headers, then submits `signed_id` through the authorized record-update API. Attach with `product.photo.attach(signed_id)`. The helper respects attachment-specific storage services. Controllers must validate allowed content types and sizes and ensure the signed blob belongs to the authorized record before attaching it.

The generic Active Storage direct-upload endpoint has no owning record and generates an opaque key. Use the record helper when direct uploads must follow the model/ID folder convention. Unattached uploads can be cleaned up using Rails' standard unattached-blob purge process.

## Verification

```bash
bin/rails test test/models/record_storage_test.rb
```

Tests verify original image bytes, new and existing records, multiple files, duplicate filenames, signed viewing/download URLs, processed and cached thumbnails, direct uploads, STI, legacy keys, and path traversal protection. S3 requests and signatures are checked with the AWS SDK's stubbed client; live cloud storage requires actual provider configuration.
