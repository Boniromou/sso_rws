class AddAuthSourceDetailIdToDomains < ActiveRecord::Migration
  def up
    add_column :domains, :auth_source_detail_id, :integer
    execute "ALTER TABLE domains ADD CONSTRAINT fk_Domains_AuthSourceDetailId FOREIGN KEY (auth_source_detail_id) REFERENCES auth_source_details(id);"
  end

  def down
    execute "ALTER TABLE domains DROP FOREIGN KEY fk_Domains_AuthSourceDetailId;"
    remove_column :domains, :auth_source_detail_id
  end
end
