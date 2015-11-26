class PropertiesSystemUser < ActiveRecord::Base
  attr_accessible :id,  :system_user_id, :property_id, :status

  belongs_to :property
  belongs_to :system_user

  scope :by_system_user_id, -> system_user_id { where(:system_user_id => system_user_id) if system_user_id.present? }
  scope :exclude_property_ids, -> property_ids { where("property_id NOT IN (?)", property_ids) if property_ids.present? }

  def self.update_properties_by_system_user(system_user_id, property_ids)
    transaction do
      property_ids.each { |property_id| grant(system_user_id, property_id) }
      handle_exclusion(system_user_id, property_ids)
    end
  end

  private
  def self.grant(system_user_id, property_id)
    if exists?(:system_user_id => system_user_id, :property_id => property_id)
      where(:system_user_id => system_user_id, :property_id => property_id).limit(1).update_all(:status => true)
    else
      create!(:system_user_id => system_user_id, :property_id => property_id, :status => true)
    end
  end

  def self.handle_exclusion(system_user_id, property_ids)
    suspended_entry = by_system_user_id(system_user_id).exclude_property_ids(property_ids)
    suspended_entry.update_all(:status => false) unless suspended_entry.blank?
  end
end
