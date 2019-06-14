class Licensee < ActiveRecord::Base
  attr_accessible :id, :name, :timezone
  has_many :casinos
  has_many :domain_licensees
  has_many :domains, :through => :domain_licensees

  serialize :sync_user_config, JSON
  serialize :sync_user_data, JSON
end
