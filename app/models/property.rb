class Property < ActiveRecord::Base
  attr_accessible :id
 
  belongs_to :casino
end
