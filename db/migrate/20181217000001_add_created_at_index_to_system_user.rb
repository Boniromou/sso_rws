class AddCreatedAtIndexToSystemUser < ActiveRecord::Migration
  def change
    add_index :system_users, :created_at, name: 'idx_created_at'
  end
end
