class AddPurgeAtToCasinos < ActiveRecord::Migration
  def change
    add_column :casinos, :purge_at, :datetime
    add_index :casinos, :purge_at
  end
end
