set :stages, %w(integration0 integration1 staging0 staging1 sandbox3 production3 production4 sandbox production ias_prd sandbox5 sandbox6 cert1 ga0 production6 sandbox8 sandbox10 esbsandbox production10 sandbox9)
set :default_stage, 'integration0'
require 'capistrano/ext/multistage'
require 'lax-capistrano-recipes/rws'
require 'bundler/capistrano'
require 'whenever/capistrano'
require 'capistrano/server_definition'
require 'capistrano/role'

set :app_server, "thin"
set :application, "sso_rws"
set :project, "rigi"
set :env_path, "/opt/deploy/env/#{application}"
set :envrc_script, "#{env_path}/.envrc"

set :third_party_home, '/opt/third-party'
set :monit_home, "#{third_party_home}/monit"
set :monit, "#{monit_home}/bin/monit"
set :monit_conf, "#{monit_home}/conf/monitrc"
set :template_home, "/opt/deploy/lib/templates"
set :config_templates, "#{template_home}/config_with_bundle"
set :script_templates, "#{template_home}/script"
set :nginx, "#{third_party_home}/nginx/sbin/nginx"
set :crontab, '/usr/bin/crontab'
set :bundle_cmd, "source #{envrc_script}; bundle"
set :whenever_command, defer {"source #{envrc_script} && bundle install && RAILS_ENV=#{stage} bundle exec whenever"}
set :whenever_environment, defer { stage }
set :whenever_roles, "app"
# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion
set :scm, "git"

set :user, "laxino"
#set :user, "guang.su"
set :group, "laxino_rnd"

# Define who should recieve alerts from Monit
set :alert_recipients, ['lucy.cheung@laxino.com', 'xiaopan.yun@laxino.com', 'ivy.hoi@laxino.com']

# Before you can execute sudo comands on the app server,
# please comment out the following line in the /etc/sudoers
#     Defaults    requiretty
set :use_sudo, false

# Define deployment destination and source,
# using lazy evaluation of variables
set(:deploy_to) { "#{env_path}/app_#{stage}" }
set(:repository) { "ssh://laxino@#{repo_host}/opt/laxino/stash_repos/#{project.sub('.', '/')}/#{application}.git" }

# Define your cron jobs here

class Capistrano::Configuration
  def role_names_for_host(host)
    roles.map {|role_name, role| role_name if role.include?(host) }.compact || []
  end
end
