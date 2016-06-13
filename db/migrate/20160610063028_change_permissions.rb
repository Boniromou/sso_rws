class ChangePermissions < ActiveRecord::Migration
  def up
  	change_column(:permissions, :name,   :string, :limit => 255, :null => false)
  	change_column(:permissions, :action, :string, :limit => 255, :null => false)
  	change_column(:permissions, :target, :string, :limit => 255, :null => false)
  end

  def down
  	change_column(:permissions, :name, 	 :string, :limit => 255, :null => true)
  	change_column(:permissions, :action, :string, :limit => 255, :null => true)
  	change_column(:permissions, :target, :string, :limit => 255, :null => true)
  end
end
