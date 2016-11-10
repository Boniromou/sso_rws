require "rails_helper"

describe App do
  fixtures :apps

  describe "test validate" do
    it "app name cannot be null" do
      count = App.count
      app = App.new
      app.save
      expect(app.errors[:name]).to include("can't be blank")
      expect(App.count).to eq count
    end
  end

  describe "test get_all_apps" do
    def delete_apps
      AppSystemUser.delete_all
      RolePermission.delete_all
      Permission.delete_all
      RoleAssignment.delete_all
      Role.delete_all
      App.delete_all
    end

  	it "success" do
  	  apps = App.get_all_apps
  	  expect(apps.length).to eq 3
      expect(apps[1]).to eq "User Management"
      expect(apps[2]).to eq "Gaming Operation"
      expect(apps[3]).to eq "Cage"
  	end

  	it "apps no data" do
      delete_apps
  	  apps = App.get_all_apps
  	  expect(apps).not_to be_nil
  	  expect(apps.length).to eq 0
  	end
  end
end