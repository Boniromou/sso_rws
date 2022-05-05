class CreateDomainLincesees < ActiveRecord::Migration
  def up
    create_table :domain_licensees do |t|
      t.integer :domain_id, :null => false
      t.integer :licensee_id, :null => false
      t.datetime :purge_at
      t.timestamps
    end

    execute "ALTER TABLE domain_licensees ADD CONSTRAINT fk_DomainLicensees_DomainId FOREIGN KEY (domain_id) REFERENCES domains(id);"
    execute "ALTER TABLE domain_licensees ADD CONSTRAINT fk_DomainLicensees_LicenseeId FOREIGN KEY (licensee_id) REFERENCES licensees(id);"
    add_index :domain_licensees, ["domain_id", "licensee_id"], :unique => true
    add_index :domain_licensees, :purge_at
  end

  def down
    drop_table :domain_licensees
  end
end
