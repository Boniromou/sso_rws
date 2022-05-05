class RolePermissionsVersion < ActiveRecord::Base
  attr_accessible :before_version, :version, :upload_apps, :upload_by, :upload_at
  scope :since, -> time { where("upload_at >= ?", time) if time.present? }
  scope :until, -> time { where("upload_at < ?", time) if time.present? }

  VERSION_FORMAT_REGEX = /#{Rails.env}_role_permission_v\d+.\d+/
  ACCEPTED_FORMATS = ['.xlsx', '.xls']

  def self.check_version!(filename)
    extname = File.extname(filename)
    version = File.basename(filename, extname)
    raise Rigi::UploadRolePermissionsFail.new("incorrect_file_name") if !ACCEPTED_FORMATS.include?(extname) || VERSION_FORMAT_REGEX.match(version).to_s != version
    raise Rigi::UploadRolePermissionsFail.new("duplicated_version") if find_by_version(version).present?
  end

  def self.insert!(version, apps, system_user)
    before_version = self.last
    before_version = before_version.version if before_version
    create!(before_version: before_version, version: version, upload_apps: apps, upload_by: system_user.username_with_domain, upload_at: Time.now.utc)
  end
end
