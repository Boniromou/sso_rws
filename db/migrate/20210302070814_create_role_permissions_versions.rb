class CreateRolePermissionsVersions < ActiveRecord::Migration
  def change
    create_table :role_permissions_versions do |t|
      t.string   :before_version
      t.string   :version,     :null => false
      t.string   :upload_apps, :limit => 255
      t.string   :upload_by,   :null => false
      t.datetime :upload_at,   :null => false
      t.timestamps
    end

    add_index :role_permissions_versions, :version, :unique => true
  end
end
