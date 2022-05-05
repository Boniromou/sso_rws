class DomainLicensee < ActiveRecord::Base
  attr_accessible :domain_id, :licensee_id
  belongs_to :domain
  belongs_to :licensee
  has_many :casinos, :through => :licensee

  validates_uniqueness_of :domain_id, scope: [:licensee_id], :message => I18n.t("alert.duplicate_domain_licensee")
  validates_presence_of :domain_id, :licensee_id, :message => I18n.t("domain_licensee.invalid_params")
end