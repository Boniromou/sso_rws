class AddDomainToAuthSources < ActiveRecord::Migration
  def change
    add_column :auth_sources, :domain, :string, :default => "", :null => false

    AuthSource.where(:name => "Laxino LDAP", :host => "10.10.28.91", :port => 389).update_all(:domain => "mo")
  end
end
