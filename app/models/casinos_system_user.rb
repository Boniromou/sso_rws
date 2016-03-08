class CasinosSystemUser < ActiveRecord::Base
  attr_accessible :id,  :system_user_id, :casino_id, :status

  belongs_to :casino
  belongs_to :system_user

  scope :by_system_user_id, -> system_user_id { where(:system_user_id => system_user_id) if system_user_id.present? }
  scope :exclude_casino_ids, -> casino_ids { where("casino_id NOT IN (?)", casino_ids) if casino_ids.present? }

  def self.update_casinos_by_system_user(system_user_id, casino_ids)
    transaction do
      casino_ids.each { |casino_id| grant(system_user_id, casino_id) }
      handle_exclusion(system_user_id, casino_ids)
    end
  end

  private
  def self.grant(system_user_id, casino_id)
    if exists?(:system_user_id => system_user_id, :casino_id => casino_id)
      where(:system_user_id => system_user_id, :casino_id => casino_id).limit(1).update_all(:status => true)
    else
      create!(:system_user_id => system_user_id, :casino_id => casino_id, :status => true)
    end
  end

  def self.handle_exclusion(system_user_id, casino_ids)
    suspended_entry = by_system_user_id(system_user_id).exclude_casino_ids(casino_ids)
    suspended_entry.update_all(:status => false) unless suspended_entry.blank?
  end

end
