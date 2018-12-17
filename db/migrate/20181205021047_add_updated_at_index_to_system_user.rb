class AddUpdatedAtIndexToSystemUser < ActiveRecord::Migration
  def change
    add_index :system_users, :updated_at, name: 'idx_updated_at'
  end
end
