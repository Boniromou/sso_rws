class CreateTests < ActiveRecord::Migration
  def up
    create_table :tests do |t|
      t.string :name, :limit => 20
      t.timestamps
    end
  end

  def down
    drop_table :tests
  end
end
