class Licensee < ActiveRecord::Base
  attr_accessible :id, :name, :auth_source_id
  has_many :casinos
  belongs_to :auth_source
  scope :unbind_licensees, -> licensee_ids {where("id not in (?)", licensee_ids) if licensee_ids.present?}
end
