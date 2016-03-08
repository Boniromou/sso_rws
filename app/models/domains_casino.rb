class DomainsCasino < ActiveRecord::Base
  attr_accessible :id,  :domain_id, :casino_id

  belongs_to :domain
  belongs_to :casino
end

