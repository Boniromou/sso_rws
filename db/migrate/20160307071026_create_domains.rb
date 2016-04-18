class CreateDomains < ActiveRecord::Migration
  def up
  	create_table :domains do |t|
      t.string :name, :limit => 45, :null => false
      t.timestamps
    end

    add_index :domains, ["name"], :unique => true
  end

  def down
  	drop_table :domains
  end
end
