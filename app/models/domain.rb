class Domain < ActiveRecord::Base
  attr_accessible :id, :name, :licensee_id

  has_many :system_users
  has_many :domains_casinos
  belongs_to :licensee
  has_many :casinos, :through => :licensee
  has_one :auth_source, :through => :licensee

  validates_presence_of :name, :message => I18n.t("alert.invalid_domain")
  # validates_uniqueness_of :name
  validates_format_of :name, :with => /^[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+$/, :on => :create, :message => I18n.t("alert.invalid_domain")

  scope :active_domain_licensee, -> {where("licensee_id is not null")}
  scope :inactive_domain_licensee, -> {where("licensee_id is null")}
  scope :get_by_domain_licensee, -> id, licensee_id {where(id: id, licensee_id: licensee_id)}

  def get_casino_ids
    casinos.pluck(:id)
  end

  def self.validate_domain!(domain)
    raise Rigi::InvalidDomain.new(I18n.t("alert.invalid_domain")) if domain.blank? || !Domain.where(:name => domain).first
  end

  def self.insert(params)
    name = params[:name].downcase
    create!(name: name)
  end

  def self.create_domain_licensee(params)
    licensee_id = params[:licensee_id]
    domain = self.find_by_id(params[:domain_id])
    raise Rigi::CreateDomainLicenseeFail.new(I18n.t("domain_licensee.invalid_params")) if domain.blank? || Licensee.find_by_id(licensee_id).blank?
    raise Rigi::CreateDomainLicenseeFail.new(I18n.t("domain_licensee.create_mapping_fail_domain_used")) if domain.licensee_id.present?
    raise Rigi::CreateDomainLicenseeFail.new(I18n.t("domain_licensee.create_mapping_fail_licensee_used")) if Domain.where(licensee_id: licensee_id).present?
    domain.licensee_id = licensee_id
    domain.save!
  end

  def self.remove_domain_licensee(params)
    domain = self.get_by_domain_licensee(params[:domain_id], params[:licensee_id]).first
    raise Rigi::DeleteDomainLicenseeFail.new(I18n.t("domain_licensee.delete_mapping_fail")) if domain.blank?
    domain.licensee_id = nil
    domain.save!
  end
end
