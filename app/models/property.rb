class Property < ActiveRecord::Base
  attr_accessible :id, :casino_id, :name, :description
 
  belongs_to :casino
end
