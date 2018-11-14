class AddSyncUserConfigToLicensee < ActiveRecord::Migration
  def up
    add_column :licensees, :sync_user_strategy, :string, :limit => 45
    add_column :licensees, :sync_user_config, :string, :limit => 1024
    add_column :licensees, :sync_user_data, :string, :limit => 1024
  end

  def down
    remove_column :licensees, :sync_user_strategy
    remove_column :licensees, :sync_user_config
    remove_column :licensees, :sync_user_data
  end
end
