class CreateLicensees < ActiveRecord::Migration
  def up
  	create_table :licensees do |t|
      t.string :name, :limit => 45, :null => false
      t.string :description, :limit => 255
      t.timestamps
    end

    add_index :licensees, ["name"], :unique => true
  end

  def down
  	drop_table :licensees
  end
end
