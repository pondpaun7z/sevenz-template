module RecordStorage
  extend ActiveSupport::Concern

  included do
    before_save :assign_record_storage_keys, if: :persisted?
    after_create :assign_record_storage_keys
  end

  class_methods do
    def has_one_attached(name, **options, &block)
      super(name, **options) do |attachment|
        attachment.variant :thumbnail, resize_to_limit: [ 320, 320 ]
        block&.call(attachment)
      end
    end

    def has_many_attached(name, **options, &block)
      super(name, **options) do |attachment|
        attachment.variant :thumbnail, resize_to_limit: [ 320, 320 ]
        block&.call(attachment)
      end
    end
  end

  # Call after authorizing access to this record in a direct-upload API.
  def create_direct_upload_blob!(name, **attributes)
    raise ArgumentError, "Save the record before creating a direct upload" unless persisted?

    reflection = self.class.reflect_on_attachment(name)
    raise ArgumentError, "Unknown attachment: #{name}" unless reflection

    service_name = reflection.options[:service_name]
    service_name = service_name.call(self) if service_name.is_a?(Proc)

    ActiveStorage::Blob.create_before_direct_upload!(
      **attributes,
      key: record_storage_key(attributes.fetch(:filename)),
      service_name: service_name
    )
  end

  private
    def assign_record_storage_keys
      attachment_changes.each_value do |change|
        blobs = if change.respond_to?(:blobs)
          change.blobs
        elsif change.respond_to?(:blob)
          [ change.blob ]
        else
          []
        end

        blobs.each do |blob|
          blob.key = record_storage_key(blob.filename) if blob.new_record?
        end
      end
    end

    def record_storage_key(filename)
      model = self.class.base_class.model_name.collection
      record_id = id.to_s.gsub(/[^a-zA-Z0-9_-]/, "_")
      "#{model}/#{record_id}/#{SecureRandom.base36(28)}-#{ActiveStorage::Filename.wrap(filename).sanitized}"
    end
end
