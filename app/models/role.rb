class Role < ActiveRecord::Base
  has_many :role_assignments, :dependent => :destroy
  has_many :system_users, :through => :role_assignments, :source => :user, :source_type => 'SystemUser'
  has_many :role_permissions
  has_many :permissions, :through => :role_permissions
  belongs_to :app 

  def has_permission?(target, action)
    result = self.permissions.collect{|x| {:action => x.action, :target => x.target}}.include?({:action => action, :target => target})
   Rails.logger.info "has_permission? on #{target} and #{action}: #{result.present?}"
   result
  end
end
