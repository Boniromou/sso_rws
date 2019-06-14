class AddTimezoneToLicensees < ActiveRecord::Migration
  def change
    add_column :licensees, :timezone, :string, :limit=>45
    Licensee.find(1000).update_attributes(timezone: '+08:00')
  end
end
