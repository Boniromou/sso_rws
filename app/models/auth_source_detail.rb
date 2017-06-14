class AuthSourceDetail < ActiveRecord::Base
  attr_accessible :data, :name
  serialize :data, JSON
  validates_uniqueness_of :name, :message => I18n.t("alert.ldap_duplicated")

  def self.insert(params)
    params = strip_whitespace(params)
    params.delete('id')
    name = params.delete('name')
    create!(:name => name, :data => params)
  end

  def self.edit(params)
    auth_source_detail = find_by_id(params.delete('id'))
    if auth_source_detail
      name = params.delete('name')
      auth_source_detail.update_attributes!(:name => name, :data => strip_whitespace(params))
    else
      auth_source_detail = insert(params)
    end
    auth_source_detail
  end

  def self.strip_whitespace(params)
    Hash[params.collect{|k,v| [k, v.to_s.strip]}]
  end
end
