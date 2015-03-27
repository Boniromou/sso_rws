# Redmine - project management software
# Copyright (C) 2006-2014  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require 'net/ldap'
require 'net/ldap/dn'
require 'timeout'

class AuthSourceLdap < AuthSource
  validates_presence_of :host, :port, :attr_login
  validates_length_of :name, :host, :maximum => 60, :allow_nil => true
  validates_length_of :account, :account_password, :base_dn, :filter, :maximum => 255, :allow_blank => true
  validates_length_of :attr_login, :attr_firstname, :attr_lastname, :attr_mail, :maximum => 30, :allow_nil => true
  validates_numericality_of :port, :only_integer => true
  validates_numericality_of :timeout, :only_integer => true, :allow_blank => true
#  validate :validate_filter

  #before_validation :strip_ldap_attributes

  def initialize(attributes=nil, *args)
    super
    self.port = 389 if self.port == 0
  end

  def authenticate(login, password)
    return false if login.blank? || password.blank?
    Rails.logger.info "[auth_source_id=#{self.id}]LDAP authenticating to #{self.name}...."
    ldap_con = initialize_ldap_con(login, password)
    ldap_con.bind ? true : false
  end

  def initialize_ldap_con(ldap_user, ldap_password)
    options = { :host => self.host,
                :port => self.port,
                :encryption => nil,
                :auth => {
                  :method => :simple,
                  :username => ldap_user,
                  :password => ldap_password
                  }
                }
    Net::LDAP.new options
  end

  def get_domain
    dn_arr = self.base_dn.split(',')
    dn_arr.first.split('=')[1]
  end
end
