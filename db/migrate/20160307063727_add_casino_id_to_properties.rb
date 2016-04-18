class AddCasinoIdToProperties < ActiveRecord::Migration
  def up
    add_column :properties, :casino_id, :integer
  end

  def down
    remove_column :properties, :casino_id
  end
end
