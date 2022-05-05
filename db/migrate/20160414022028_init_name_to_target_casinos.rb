class InitNameToTargetCasinos < ActiveRecord::Migration
  def up
    execute "UPDATE target_casinos, casinos SET target_casinos.target_casino_name = casinos.name WHERE target_casinos.target_casino_id = casinos.id"
  end

  def down
  end
end
