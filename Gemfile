# source 'https://rubygems.org'
source 'http://gems:8808'

gem 'rails', '3.2.13'
gem 'ruby-saml', '1.3.1'
gem 'mysql2', '0.3.17'
gem 'sequel', '3.41.0'
gem 'rack-cors'
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
gem 'net-sftp', '2.1.2'

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
  gem 'database_cleaner', '1.4.1'
  gem 'capybara', '2.4.3'
  gem 'poltergeist', '1.9.0'
  gem 'phantomjs', '2.1.1', :require => 'phantomjs/poltergeist'
  gem 'simplecov'
  gem 'factory_girl', '4.5.0'
  #gem 'capybara-webkit'
end

gem "pundit",  '0.3.0'
gem 'whenever', :require => false
gem 'spreadsheet', '1.1.2'
gem 'jwt', '1.5.6'
gem 'roo', '2.7.1'
gem 'roo-xls', '1.1.0'
gem 'httparty', '0.14.0'
