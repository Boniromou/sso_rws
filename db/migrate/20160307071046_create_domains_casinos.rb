class CreateDomainsCasinos < ActiveRecord::Migration
  def up
  	create_table :domains_casinos do |t|
      t.integer :domain_id, :null => false
      t.integer :casino_id, :null => false
      t.timestamps
    end
    add_index :domains_casinos, ["domain_id", "casino_id"], :unique => true
  end

  def down
    drop_table :domains_casinos
  end
end
