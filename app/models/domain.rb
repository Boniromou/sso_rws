class Domain < ActiveRecord::Base
  attr_accessible :id, :name, :auth_source_detail_id
  has_many :domain_licensees
  has_many :system_users
  has_many :licensees, :through => :domain_licensees
  belongs_to :auth_source_detail
  has_many :casinos, :through => :licensees

  validates_presence_of :name, :message => I18n.t("alert.invalid_params")
  validates_format_of :name, :with => /^[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+$/, :on => :create, :message => I18n.t("alert.invalid_domain")
  validates_uniqueness_of :name, :message => I18n.t("alert.domain_duplicated")

  def get_casino_ids
    casinos.pluck(:id)
  end

  def self.validate_domain!(domain)
    raise Rigi::InvalidDomain.new(I18n.t("alert.invalid_domain")) if domain.blank? || !Domain.where(:name => domain).first
  end

  def self.insert(domain, auth_source_detail)
    transaction do
      auth_source_detail = AuthSourceDetail.insert(auth_source_detail)
      create!(name: domain[:name].to_s.strip.downcase, auth_source_detail_id: auth_source_detail.id)
    end
  end

  def edit(auth_source_detail)
    transaction do
      auth_source_detail = AuthSourceDetail.edit(auth_source_detail)
      update_attributes!(auth_source_detail_id: auth_source_detail.id)
    end
  end
end
