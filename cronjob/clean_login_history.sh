#!/bin/sh
source /opt/deploy/env/sso_rws/.envrc
cd /opt/deploy/env/sso_rws/app_$1/current/
bundle exec /opt/deploy/env/sso_rws/app_$1/current/cronjob/rake login_history:clean_login_history RAILS_ENV=$1 
source /opt/deploy/env/sso_rws/.unset_envrc
