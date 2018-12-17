class AddUpdatedAtIndexToTargetCasino < ActiveRecord::Migration
  def change
    add_index :target_casinos, :updated_at, name: 'idx_updated_at'
  end
end
