class CreateAuthSourceDetails < ActiveRecord::Migration
  def up
    create_table :auth_source_details do |t|
      t.string :name
      t.text :data, :null => false
      t.timestamps
    end
  end

  def down
    drop_table :auth_source_details
  end
end
