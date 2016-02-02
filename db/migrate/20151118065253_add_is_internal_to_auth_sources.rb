class AddIsInternalToAuthSources < ActiveRecord::Migration
  def change
    add_column :auth_sources, :is_internal, :boolean, :default => false, :null => false
  end
end
