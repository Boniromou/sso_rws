class AddTimezoneToLicensees < ActiveRecord::Migration
  def change
    add_column :licensees, :timezone, :string, :limit => 45
    execute "UPDATE licensees SET timezone = '+08:00' WHERE id = 1000"
  end
end
