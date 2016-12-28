class Casino < ActiveRecord::Base
  attr_accessible :id, :licensee_id, :name, :description

  belongs_to :licensee
  has_many :properties
  has_many :casinos_system_users
  has_many :system_users, :through => :casinos_system_users
end
