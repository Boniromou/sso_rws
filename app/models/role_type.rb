class RoleType < ActiveRecord::Base
  attr_accessible :id, :name, :description

  def self.get_all_role_types
	RoleType.all.map {|type| {type.id => I18n.t("role_type.#{type.name}")}}.inject(:merge) || {}
  end
end
