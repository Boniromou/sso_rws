class CreateApps < ActiveRecord::Migration
  class App < ActiveRecord::Base
    attr_accessible :name
  end

  def up
    create_table :apps do |t|
      t.string :name
      t.timestamps
    end
   
    App.create!(:name => "user")
    App.create!(:name => "operation")
    App.create!(:name => "cage")
  end

  def down
    drop_table :apps
  end
end
