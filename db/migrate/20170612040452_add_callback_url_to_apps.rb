class AddCallbackUrlToApps < ActiveRecord::Migration
  def change
    add_column :apps, :callback_url, :string, :limit => 255
  end
end
