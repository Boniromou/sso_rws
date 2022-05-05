class AddCreatedAtIndexToCasinosSystemUser < ActiveRecord::Migration
  def change
    add_index :casinos_system_users, :created_at, name: 'idx_created_at'
  end
end
