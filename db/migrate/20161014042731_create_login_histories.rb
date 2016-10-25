class CreateLoginHistories < ActiveRecord::Migration
  def up
  	create_table :login_histories do |t|
      t.integer  :system_user_id, :null => false
      t.integer  :domain_id, 			:null => false
      t.integer  :app_id, 				:null => false
      t.string   :detail, 				:limit => 1024, :default => '{}'
      t.datetime :sign_in_at, 		:null => false
      t.datetime :purge_at
      t.timestamps
    end

    add_index :login_histories, ["system_user_id"]
    add_index :login_histories, ["domain_id"]
    add_index :login_histories, ["app_id"]
    add_index :login_histories, ["sign_in_at"]
  end

  def down
    remove_index :login_histories, ["system_user_id"]
    remove_index :login_histories, ["domain_id"]
    remove_index :login_histories, ["app_id"]
    remove_index :login_histories, ["sign_in_at"]
    drop_table :login_histories
  end
end
