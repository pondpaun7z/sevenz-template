require "active_storage/service/disk_service"

class ActiveStorage::Service::RecordDiskService < ActiveStorage::Service::DiskService
  private
    # Keep Rails' path validation and support existing opaque, sharded keys.
    def folder_for(key)
      key.include?("/") ? "" : super
    end
end
