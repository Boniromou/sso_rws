class AddTimezoneToLicensees < ActiveRecord::Migration
  def change
    add_column :licensees, :timezone, :string, :limit=>45
  end
end
