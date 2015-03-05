class AddNameAndDescriptionToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :name, :string
    add_column :properties, :description, :string, :length => 255
  end
end
