class CreateRoles < ActiveRecord::Migration
=begin
  class Role < ActiveRecord::Base
    attr_accessible :name
  end
=end

  def change
    create_table :roles do |t|
      t.string :name, :limit => 255
      t.timestamps
    end
=begin
    Role.create!(:name => "user_manager")
    Role.create!(:name => "system_operator")
    Role.create!(:name => "helpdesk")
    Role.create!(:name => "property_operator")
    Role.create!(:name => "auditor")
=end
  end
end
