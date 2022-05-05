class AddTypeToDomains < ActiveRecord::Migration
  def change
    add_column :domains, :user_type, :string, :limit => 45
  end
end
