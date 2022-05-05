require 'rake'

namespace :system_user do
  desc "Sync system users to sso ..."
  task :sync_system_user => [:environment] do
    Rails.logger.info "Begin to Sync system user info"
    SystemUser.sync_user_info
    Rails.logger.info "End to Sync system user info"
  end

  task :sync_sftp_user => [:environment] do
    Rails.logger.info "Begin to Sync user info from sftp"
    SftpService.new.sync_user_info
    Rails.logger.info "End to Sync user info from sftp"
  end
end

