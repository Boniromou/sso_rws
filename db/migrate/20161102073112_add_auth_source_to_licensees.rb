class AddAuthSourceToLicensees < ActiveRecord::Migration
  def up
    add_column :licensees, :auth_source_id, :integer
    execute "ALTER TABLE licensees ADD CONSTRAINT fk_Licensees_AuthSourceId FOREIGN KEY (auth_source_id) REFERENCES auth_sources(id);"
  end

  def down
    execute "ALTER TABLE licensees DROP FOREIGN KEY fk_Licensees_AuthSourceId;"
    remove_column :licensees, :auth_source_id
  end
end
