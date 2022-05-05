class AddTimezoneToLicensees < ActiveRecord::Migration
  def change
    add_column :licensees, :timezone, :string, :limit => 45
    execute "UPDATE licensees SET timezone = 'Asia/Macao' WHERE id = 1000"
  end
end
