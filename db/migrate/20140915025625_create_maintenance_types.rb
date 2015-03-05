class CreateMaintenanceTypes < ActiveRecord::Migration
  class MaintenanceType < ActiveRecord::Base
    attr_accessible :name
  end

  def up
    create_table :maintenance_types do |t|
      t.string :name, :limit => 255
      t.timestamps
    end

    MaintenanceType.create!(:name => "per_property")
    MaintenanceType.create!(:name => "per_game")
    MaintenanceType.create!(:name => "per_game_type")
  end

  def down
    drop_table :maintenance_types
  end
end
