class ChangeAppsNameNotNull < ActiveRecord::Migration
  def up
    change_column(:apps, :name, :string, :limit => 255, :null => false)
  end

  def down
  	change_column(:apps, :name, :string, :limit => 255, :null => true)
  end
end
