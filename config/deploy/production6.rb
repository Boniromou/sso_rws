# Define your release to be deployed to integration environment here.
# Release number for integration environment is supposed to be odd numbers.
set :branch, 'CBG_0_6_10'

# Define your repository server for integration environment here.
#   production SVN - svn.prod.laxigames.com
#   development SVN - svn.mo.laxino.com
set :user, "swe"
set :group, "swe"
set :repo_host, 'cbms-app01.snd6.gamesource.local'

# Define your application servers for integration environment here.
#   int - Integration
#   stg - Staging
#   prd - Production
role :app, 'sso-app01.prd6.gamesource.local'

role :cronjob_app, 'sso-app01.prd6.gamesource.local'

#role :cronjob_app, 'int-cons-vapp03.rnd.laxino.com'

# Define your database servers for integration environment here.
# role :db,  "int-cons-db01.rnd.laxino.com", :primary => true

# Define your application cluster with Nginx settings here
# These variables will be used in generating Nginx/Thin config files
set :nginx_worker_processes, 2
set :cluster_port, 10040
set :virtual_server_name, 'sso-vapp01.prd6.gamesource.local'
set :num_of_servers, 2

set :keep_releases, 2
after 'deploy', 'deploy:cleanup'
