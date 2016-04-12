class AddNameToTargetCasinos < ActiveRecord::Migration
  def up
    add_column(:target_casinos, :target_casino_name, :string)
  end

  def down
    remove_column(:target_casinos, :target_casino_name)
  end
end
