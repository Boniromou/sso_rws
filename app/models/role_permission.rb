class RolePermission < ActiveRecord::Base
  attr_accessible :role_id, :permission_id, :value
  belongs_to :role
  belongs_to :permission

  def self.change_permissions!(role_permissions)
    grant_all!(role_permissions[:grant])
    revoke_all!(role_permissions[:revoke])
  end

  def self.grant_all!(role_permissions)
    role_permissions.each do |data|
      role_id = Role.where(name: data[:role], app_id: data[:app_id]).first.id
      permission_id = Permission.where(target: data[:target], action: data[:action], app_id: data[:app_id]).first.id
      role_permission = where(role_id: role_id, permission_id: permission_id).first
      if role_permission
        role_permission.update_attributes!(value: data[:value])
      else
        create!(role_id: role_id, permission_id: permission_id, value: data[:value])
      end
    end
  end

  def self.revoke_all!(role_permissions)
    role_permissions.each do |data|
      role_id = Role.where(name: data[:role], app_id: data[:app_id]).first.id
      permission_id = Permission.where(target: data[:target], action: data[:action], app_id: data[:app_id]).first
      where(role_id: role_id, permission_id: permission_id).delete_all
    end
  end
end
