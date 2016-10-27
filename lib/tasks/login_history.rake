require 'rake'

namespace :login_history do
  desc "clean login histories..."
  task :clean_login_history => [:environment] do
    LoginHistory.clean_login_history
  end
end

