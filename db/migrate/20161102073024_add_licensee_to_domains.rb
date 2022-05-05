class AddLicenseeToDomains < ActiveRecord::Migration
  def up
    add_column :domains, :licensee_id, :integer
    add_index :domains, ["licensee_id"], :unique => true
    execute "ALTER TABLE domains ADD CONSTRAINT fk_Domains_LicenseeId FOREIGN KEY (licensee_id) REFERENCES licensees(id);"
  end

  def down
    execute "ALTER TABLE domains DROP FOREIGN KEY fk_Domains_LicenseeId;"
    remove_index :domains, ["licensee_id"]
    remove_column :domains, :licensee_id
  end
end
