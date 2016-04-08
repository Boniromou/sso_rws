class Domain < ActiveRecord::Base
  attr_accessible :id, :name

  has_many :system_users
  has_many :domains_casinos
  has_many :casinos, :through => :domains_casinos

  def get_casino_ids
    domains_casinos.pluck(:casino_id)
  end

  def self.validate_domain!(domain)
    raise Rigi::InvalidDomain.new(I18n.t("alert.invalid_domain")) if domain.blank? || !Domain.where(:name => domain).first
  end
end
