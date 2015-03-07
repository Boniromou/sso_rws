class Role < ActiveRecord::Base
  has_many :role_assignments, :dependent => :destroy
  has_many :system_users, :through => :role_assignments, :source => :user, :source_type => 'SystemUser'
  has_many :role_permissions
  has_many :permissions, :through => :role_permissions
  belongs_to :app 

  def has_permission?(action)
    result = self.permissions.collect{|x| x.action}.include?(action)
p "00000 #{action} 00000"
 p result
    result
  end
end
