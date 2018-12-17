class AddUpdatedAtIndexToChangeLog < ActiveRecord::Migration
  def change
    add_index :change_logs, :updated_at, name: 'idx_updated_at'
  end
end
