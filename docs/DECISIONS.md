# Project decisions

## 2026-10-07: Provide named image thumbnails with libvips

Context: Attachment previews need smaller images while preserving original files. `image_processing` 2.2 does not bundle a processing backend.
Decision: Add `ruby-vips`, explicitly select the libvips variant processor, and register a default `:thumbnail` variant on application model attachments with `resize_to_limit: [320, 320]`. Provide a Vue component consuming original and thumbnail URLs.
Consequence: Thumbnails are generated on demand, cached by Active Storage in the source blob's storage service, and served through signed representation URLs. Deployment needs libvips, already present in the Docker image. Model attachment blocks retain custom variant definitions; non-image files use ordinary links.

## 2026-10-07: Store uploads under model and record folders

Context: Opaque, extensionless Active Storage disk files are difficult to open and inspect outside Rails.
Decision: Assign new application-model uploads keys containing the base model collection, record ID, and a unique sanitized filename. Use a Disk service subclass that retains Rails path validation while avoiding extra sharding for scoped keys. Serve signed links under `/storage` and allow S3-compatible storage through environment configuration.
Consequence: Original files retain their extensions on disk and in cloud keys. Existing blobs keep their keys and storage services. Direct uploads need a saved, authorized owning record and the record-scoped blob helper to obtain scoped keys. Generic direct uploads and generated variants retain standard Active Storage behavior.

## 2026-10-07: Use built-in file routing and layout discovery

Context: The page and layout plugins pull in unpatched `braces`, failing the full npm security audit.
Decision: Use the installed Vue Router 5 Vite plugin for file-based pages and Vite glob imports for layouts.
Consequence: Remove both vulnerable plugin dependency chains while retaining default, named, nested, and disabled layouts. Generated routes are imported from `vue-router/auto-routes`.
