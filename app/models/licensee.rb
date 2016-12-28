class Licensee < ActiveRecord::Base
  attr_accessible :id, :name, :domain_id
  has_many :casinos
  belongs_to :domain
  scope :active_domain_licensee, -> {where("domain_id is not null")}
  scope :inactive_domain_licensee, -> {where("domain_id is null")}
  scope :get_by_domain_licensee, -> id, domain_id {where(id: id, domain_id: domain_id)}

  def self.create_domain_licensee(params)
    domain_id = params[:domain_id]
    licensee = self.find_by_id(params[:licensee_id])
    raise Rigi::CreateDomainLicenseeFail.new(I18n.t("domain_licensee.invalid_params")) if licensee.blank? || Domain.find_by_id(domain_id).blank?
    raise Rigi::CreateDomainLicenseeFail.new(I18n.t("domain_licensee.create_mapping_fail_licensee_used")) if licensee.domain_id.present?
    licensee.domain_id = domain_id
    licensee.save!
  end

  def self.remove_domain_licensee(params)
    licensee = self.get_by_domain_licensee(params[:licensee_id], params[:domain_id]).first
    raise Rigi::DeleteDomainLicenseeFail.new(I18n.t("domain_licensee.delete_mapping_fail")) if licensee.blank?
    licensee.domain_id = nil
    licensee.save!
  end
end
