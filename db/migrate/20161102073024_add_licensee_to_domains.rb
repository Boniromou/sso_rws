class AddLicenseeToDomains < ActiveRecord::Migration
  def up
    add_column :domains, :licensee_id, :integer
    execute "ALTER TABLE domains ADD CONSTRAINT fk_Domains_LicenseeId FOREIGN KEY (licensee_id) REFERENCES licensees(id);"
  end

  def down
    execute "ALTER TABLE domains DROP FOREIGN KEY fk_Domains_LicenseeId;"
    remove_column :domains, :licensee_id
  end
end
