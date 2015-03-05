class Property < ActiveRecord::Base
  has_many :maintenances

  attr_accessible :id
end
