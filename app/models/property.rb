class Property < ActiveRecord::Base
  attr_accessible :id

  has_many :properties_system_users
  has_many :system_users, :through => :properties_system_users
end
