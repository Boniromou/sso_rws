class AddTokenTypeToApps < ActiveRecord::Migration
  def change
    add_column :apps, :token_type, :string, :limit => 45
  end
end
