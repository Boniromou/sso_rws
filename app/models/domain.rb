class Domain < ActiveRecord::Base
  attr_accessible :id, :name, :auth_source_id

  has_many :system_users
  has_many :licensees
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

  def self.insert(domain, auth_source)
    transaction do
      auth_source = AuthSource.insert(auth_source)
      create!(name: domain[:name].to_s.strip.downcase, auth_source_id: auth_source.id)
    end
  end

  def edit(auth_source)
    transaction do
      auth_source = AuthSource.edit(auth_source)
      update_attributes!(auth_source_id: auth_source.id)
    end
  end
end
