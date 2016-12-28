# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

every 6.hours do
  command "/opt/deploy/env/sso_rws/app_#{ENV['RAILS_ENV']}/current/cronjob/sync_system_user.sh #{ENV['RAILS_ENV']}"
end

every 1.days do
  command "/opt/deploy/env/sso_rws/app_#{ENV['RAILS_ENV']}/current/cronjob/clean_login_history.sh #{ENV['RAILS_ENV']}"
end

# Learn more: http://github.com/javan/whenever
