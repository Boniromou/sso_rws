class Permission < ActiveRecord::Base
  attr_accessible :name, :action, :target, :app_id
  validates_presence_of :name, :action, :target
  has_many :role_permissions
  has_many :roles, :through => :role_permissions
  belongs_to :app

  def self.get_all_permissions
  	permissions = Permission.order(:target).group_by(&:app_id).map{|k,v| Hash[k, v.group_by(&:target)]}.inject(:merge) || {}
  end

  def self.create_or_update_all!(permission_data)
    permission_data.each do |data|
      permission = where(target: data[:target], action: data[:action], app_id: data[:app_id]).first
      permission ? permission.update_attributes!(data) : create!(data)
    end
  end
end
