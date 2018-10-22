class Licensee < ActiveRecord::Base
  attr_accessible :id, :name
  has_many :casinos
end
