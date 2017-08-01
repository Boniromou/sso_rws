class AddPurgeAtToLicensees < ActiveRecord::Migration
  def change
    add_column :licensees, :purge_at, :datetime
    add_index :licensees, :purge_at
  end
end
