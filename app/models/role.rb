class Role < ActiveRecord::Base
  has_many :role_assignments, :dependent => :destroy
  has_many :system_users, :through => :role_assignments, :source => :user, :source_type => 'SystemUser'

end
