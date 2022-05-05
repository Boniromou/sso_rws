class AddSessionTokenToLoginHistory < ActiveRecord::Migration
  def change
    add_column :login_histories, :sign_out_at, :datetime
    add_column :login_histories, :session_token, :string, :limit => 45

    add_index :login_histories, [:system_user_id, :session_token], name: 'idx_user_session_token'
  end
end
