class ChangeRolesNameNotNull < ActiveRecord::Migration
  def up
  	change_column(:roles, :name, :string, :limit => 255, :null => false)
  end

  def down
  	change_column(:roles, :name, :string, :limit => 255, :null => true)
  end
end
