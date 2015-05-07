#source 'https://rubygems.org'
source 'http://gems:8808'

gem 'rails', '3.2.13'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'mysql2', '0.3.16'

gem 'lax-support', '0.6.32', :git => 'ssh://git/opt/laxino/git_repos/tools/lax-support.git', :tag => 'REL_0_6_32'
gem 'sequel', '3.41.0'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
   gem 'sass-rails',   '~> 3.2.3'
   gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

   gem 'uglifier', '>= 1.0.3'
end

gem 'therubyracer', :platforms => :ruby
gem 'jquery-rails', '~> 3.1.1'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'
gem 'devise', '3.2.4'
gem 'thin', '1.6.2'

group :development, :test do
  gem 'rspec-rails', '~> 3.0.0'
end

# Optional gem for LDAP authentication
group :ldap do
  gem "net-ldap", "~> 0.3.1"
end

#gem 'pundit', '0.3.0'
#gem "devise_ldap_authenticatable", "~> 0.8.1"
#gem 'nokogiri', '1.5.5' 
#gem 'execjs', '2.2.1'
#gem 'therubyracer'
#gem 'execjs'

gem 'dalli', "~> 2.0.3"

group :test do
  gem 'capybara', '2.4.3'
  gem 'poltergeist'
  gem 'phantomjs', :require => 'phantomjs/poltergeist'
  gem 'simplecov'
  #gem 'capybara-webkit'
end

gem "pundit",  '0.3.0'
