class App < ActiveRecord::Base
  has_many :roles
  has_many :app_system_users
  has_many :system_users, :through => :app_system_users
end
