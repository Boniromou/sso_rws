class AddUpdatedAtIndexToCasinosSystemUser < ActiveRecord::Migration
  def change
    add_index :casinos_system_users, :updated_at, name: 'idx_updated_at'
  end
end
