require 'rake'

namespace :system_user do
  desc "Sync system users from ad to sso ..."
  task :sync_system_user => [:environment] do
    SystemUser.sync_user_info
  end
end

