class Domain < ActiveRecord::Base
  attr_accessible :id, :name

  has_many :system_users
  has_many :domains_casinos
  has_many :casinos, :through => :domains_casinos

  validates_presence_of :name, :message => 'domain name can not be empty'
  validates_uniqueness_of :name
  validates_format_of :name, :with => /^(([a-zA-Z]{1})|([a-zA-Z]{1}[a-zA-Z]{1})|([a-zA-Z]{1}[0-9]{1})|([0-9]{1}[a-zA-Z]{1})|([a-zA-Z0-9][a-zA-Z0-9-_]{1,61}[a-zA-Z0-9]))\.([a-zA-Z]{2,6}|[a-zA-Z0-9-]{2,30}\.[a-zA-Z]{2,3})$/, :on => :create

  def get_casino_ids
    domains_casinos.pluck(:casino_id)
  end

  def self.insert(params)
    name = params[:name].downcase
    create!(name: name)
  end
end
