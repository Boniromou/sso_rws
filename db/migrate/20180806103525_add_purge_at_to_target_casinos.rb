class AddPurgeAtToTargetCasinos < ActiveRecord::Migration
  def change
    add_column :target_casinos, :purge_at, :datetime
    add_index :target_casinos, :purge_at
 end
end
