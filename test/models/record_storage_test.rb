require "test_helper"
require "base64"

class StorageExample < ApplicationRecord
  has_one_attached :image do |attachment|
    attachment.variant :small, resize_to_limit: [ 80, 80 ]
  end
  has_many_attached :documents
  validates :title, presence: true
end

class SpecialStorageExample < StorageExample
end

class RecordStorageTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false
  parallelize(workers: 1)

  PNG = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=")

  setup do
    ActiveRecord::Base.connection.create_table :storage_examples, temporary: true do |t|
      t.string :title
      t.string :type
    end
    StorageExample.reset_column_information
  end

  teardown do
    ActiveStorage::Attachment.delete_all
    ActiveStorage::Blob.find_each(&:purge)
    ActiveRecord::Base.connection.drop_table :storage_examples
  end

  test "new records store real image bytes under the model and assigned id" do
    record = StorageExample.new(title: "Image")
    record.image.attach(io: StringIO.new(PNG), filename: "ภาพ.png", content_type: "image/png")
    record.save!

    blob = record.image.blob
    assert_match %r{\Astorage_examples/#{record.id}/[a-z0-9]+-ภาพ\.png\z}, blob.key
    assert_equal File.join(blob.service.root, blob.key), blob.service.path_for(blob.key)
    assert_equal PNG, File.binread(blob.service.path_for(blob.key))
    assert_equal PNG, record.image.download
  end

  test "existing records support multiple files and duplicate filenames" do
    record = StorageExample.create!(title: "Documents")
    record.documents.attach([
      { io: StringIO.new("first"), filename: "invoice.pdf", content_type: "application/pdf" },
      { io: StringIO.new("second"), filename: "invoice.pdf", content_type: "application/pdf" }
    ])

    blobs = record.documents.blobs.to_a
    assert_equal 2, blobs.map(&:key).uniq.size
    assert_equal [ "first", "second" ], blobs.map(&:download)
    assert blobs.all? { |blob| blob.key.start_with?("storage_examples/#{record.id}/") }

    keys = blobs.map(&:key)
    record.documents.attach(io: StringIO.new("third"), filename: "more.txt")
    assert_equal keys, record.documents.blobs.first(2).map(&:key)
    assert_equal 3, record.documents.count
  end

  test "STI records use the base model folder and sanitize filenames" do
    record = SpecialStorageExample.create!(title: "Special")
    record.image.attach(io: StringIO.new(PNG), filename: "../../photo.png", content_type: "image/png")

    assert_match %r{\Astorage_examples/#{record.id}/[a-z0-9]+-\.\.-\.\.-photo\.png\z}, record.image.blob.key
    assert_equal PNG, record.image.download
  end

  test "invalid records do not create blobs or files" do
    record = StorageExample.new
    record.image.attach(io: StringIO.new(PNG), filename: "photo.png", content_type: "image/png")

    assert_no_difference "ActiveStorage::Blob.count" do
      assert_not record.save
    end
  end

  test "signed storage URLs return inline image bytes and reject invalid signatures" do
    record = StorageExample.create!(title: "Image URL")
    record.image.attach(io: StringIO.new(PNG), filename: "photo.png", content_type: "image/png")
    path = Rails.application.routes.url_helpers.rails_blob_path(record.image, only_path: true)

    assert path.start_with?("/storage/")
    get path
    assert_response :redirect
    assert URI(response.location).path.start_with?("/storage/disk/")
    follow_redirect!
    assert_response :success
    assert_equal "image/png", response.media_type
    assert_equal PNG, response.body.b
    assert_includes response.headers["Content-Disposition"], "inline"

    get "/storage/disk/invalid/photo.png"
    assert_response :not_found
  end

  test "download URLs return file bytes with attachment disposition" do
    record = StorageExample.create!(title: "Download")
    record.documents.attach(io: StringIO.new("file contents"), filename: "notes.txt")
    get Rails.application.routes.url_helpers.rails_blob_path(record.documents.first, disposition: :attachment, only_path: true)
    follow_redirect!

    assert_response :success
    assert_equal "file contents", response.body
    assert_includes response.headers["Content-Disposition"], "attachment"
  end

  test "thumbnail URLs process and cache real resized images without changing originals" do
    original = Vips::Image.black(640, 320).write_to_buffer(".png")
    record = StorageExample.create!(title: "Thumbnail")
    record.image.attach(io: StringIO.new(original), filename: "large.png", content_type: "image/png")
    variant = record.image.variant(:thumbnail)
    path = Rails.application.routes.url_helpers.rails_representation_path(variant, only_path: true)

    assert path.start_with?("/storage/representations/")
    assert_difference "ActiveStorage::VariantRecord.count", 1 do
      get path
      assert_response :redirect
      follow_redirect!
      assert_response :success
    end

    image = Vips::Image.new_from_buffer(response.body.b, "")
    assert_equal [ 320, 160 ], [ image.width, image.height ]
    assert_equal original, record.image.download
    assert_includes response.headers["Content-Disposition"], "inline"

    assert_no_difference "ActiveStorage::VariantRecord.count" do
      get path
      follow_redirect!
      assert_response :success
    end
  end

  test "thumbnail supports image collections and keeps declared custom variants" do
    original = Vips::Image.black(120, 240).write_to_buffer(".png")
    record = StorageExample.create!(title: "Image collection")
    record.documents.attach(io: StringIO.new(original), filename: "portrait.png", content_type: "image/png")
    thumbnail = record.documents.first.variant(:thumbnail).processed
    image = Vips::Image.new_from_buffer(thumbnail.download, "")

    assert_equal [ 120, 240 ], [ image.width, image.height ]
    assert_equal [ 80, 80 ], StorageExample.reflect_on_attachment(:image).named_variants[:small].transformations[:resize_to_limit]
    assert_equal original, record.documents.first.download
  end

  test "record-scoped direct uploads retain their key when attached" do
    record = StorageExample.create!(title: "Direct upload")
    blob = record.create_direct_upload_blob!(:image, filename: "photo.png", byte_size: PNG.bytesize,
      checksum: Digest::MD5.base64digest(PNG), content_type: "image/png")
    key = blob.key

    ActiveStorage::Current.set(url_options: { host: "www.example.com" }) do
      put blob.service_url_for_direct_upload, params: PNG,
        headers: blob.service_headers_for_direct_upload
    end
    assert_response :no_content
    record.image.attach(blob.signed_id)

    assert_equal key, record.image.blob.reload.key
    assert key.start_with?("storage_examples/#{record.id}/")
    assert_equal PNG, record.image.download
  end

  test "direct uploads require a saved record and a declared attachment" do
    assert_raises(ArgumentError) { StorageExample.new.create_direct_upload_blob!(:image) }
    record = StorageExample.create!(title: "Direct upload")
    assert_raises(ArgumentError) { record.create_direct_upload_blob!(:missing) }
  end

  test "cloud uploads use the same record key and generate signed S3 URLs" do
    cloud = ActiveStorage::Service.configure(:cloud,
      cloud: Rails.application.config.active_storage.service_configurations.fetch("cloud").merge(
        "bucket" => "storage-test", "access_key_id" => "test", "secret_access_key" => "test",
        "stub_responses" => true
      )
    )
    record = StorageExample.create!(title: "Cloud")
    record.image.attach(io: StringIO.new(PNG), filename: "photo.png", content_type: "image/png")
    blob = record.image.blob
    cloud.upload(blob.key, StringIO.new(PNG), checksum: blob.checksum, content_type: blob.content_type)

    upload = cloud.client.client.api_requests.find { |request| request[:operation_name] == :put_object }
    assert_equal blob.key, upload[:params][:key]
    assert_equal "storage-test", upload[:params][:bucket]
    assert_equal "image/png", upload[:params][:content_type]
    url = cloud.url(blob.key, expires_in: 5.minutes, filename: blob.filename,
      content_type: blob.content_type, disposition: :inline)
    assert_includes URI(url).path, "/storage_examples/#{record.id}/"
    assert_includes URI(url).query, "X-Amz-Signature"
  end

  test "legacy keys remain readable and traversal keys are rejected" do
    service = ActiveStorage::Blob.service
    key = SecureRandom.base36(28)
    service.upload(key, StringIO.new("legacy"))

    assert_equal "legacy", service.download(key)
    assert_equal File.join(service.root, key[0..1], key[2..3], key), service.path_for(key)
    assert_raises(ActiveStorage::InvalidKeyError) { service.path_for("../outside.png") }
    assert_raises(ActiveStorage::InvalidKeyError) { service.path_for("model/1/../outside.png") }
  ensure
    service&.delete(key) if key
  end
end
