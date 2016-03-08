class Licensee < ActiveRecord::Base
  attr_accessible :id

  has_many :casinos
end
