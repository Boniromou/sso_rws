class DomainsCasino < ActiveRecord::Base
  attr_accessible :id,  :domain_id, :casino_id, :status

  belongs_to :domain
  belongs_to :casino

  scope :active_domain_casinos, -> {where(status: 1)}

  def self.insert(params)
    domain_id = params[:domain_id]
    casino_id = params[:casino_id]
    domain_casino = DomainsCasino.where(domain_id: domain_id, casino_id: casino_id).first

    if domain_casino && domain_casino.status == false
      domain_casino.active
    else
      create(params)
    end
  end

  def self.inactive(id)
    domain_casino = where(id: id, status: true).first
    if domain_casino
      domain_casino.inactive
    else
      raise Rigi::DomainCasinoNotFound
    end
  end

  def domain_name
    self.domain.name
  end

  def casino_name
    self.casino.name
  end

  def active
    self.status = 1
    self.save!
  end

  def inactive
    self.status = 0
    self.save!
  end
end