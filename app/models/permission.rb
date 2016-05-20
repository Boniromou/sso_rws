class Permission < ActiveRecord::Base
  has_many :role_permissions
  has_many :roles, :through => :role_permissions
  belongs_to :app

  def self.get_all_permissions
  	permissions = Permission.order(:target).group_by(&:app_id).map{|k,v| Hash[k, v.group_by(&:target)]}.inject(:merge) || {}
  end
end
