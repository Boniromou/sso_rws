class AddDomainIdToSystemUsers < ActiveRecord::Migration
  def up  
    add_column :system_users, :domain_id, :integer    
  end

  def down    
    remove_column :system_users, :domain_id
  end
end
