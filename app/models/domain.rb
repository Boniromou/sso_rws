class Domain < ActiveRecord::Base
  attr_accessible :id, :name

  has_many :system_users
  has_many :domains_casinos
  has_many :casinos, :through => :domains_casinos

  def get_casino_ids
    domains_casinos.pluck(:casino_id)
  end
end
