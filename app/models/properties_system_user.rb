class PropertiesSystemUser < ActiveRecord::Base
  attr_accessible :id,  :system_user_id, :property_id, :status

  belongs_to :property
  belongs_to :system_user

  scope :by_system_user_id, -> system_user_id { where(:system_user_id => system_user_id) if system_user_id.present? }
  scope :exclude_property_ids, -> property_ids { where("property_id NOT IN (?)", property_ids) if property_ids.present? }

  def self.update_properties_by_system_user(system_user_id, property_ids)
    transaction do
      property_ids.each do |property_id|
        unless exists?(:system_user_id => system_user_id, :property_id => property_id)
          create!(:system_user_id => system_user_id, :property_id => property_id, :status => true)
        end
      end

      suspended_entry = by_system_user_id(system_user_id).exclude_property_ids(property_ids)
      suspended_entry.update_all(:status => false) unless suspended_entry.blank?
    end
  end
end
