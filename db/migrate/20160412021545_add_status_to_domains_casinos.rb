class AddStatusToDomainsCasinos < ActiveRecord::Migration
  def up
    add_column(:domains_casinos, :status, :boolean, default: 1)
  end

  def down
    remove_column(:domains_casinos, :status)
  end
end