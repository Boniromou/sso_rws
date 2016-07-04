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
  	it "success" do
  	  apps = App.get_all_apps
  	  expect(apps.length).to eq 3
      expect(apps[1]).to eq "User Management"
      expect(apps[2]).to eq "Gaming Operation"
      expect(apps[3]).to eq "Cage"
  	end

  	it "apps no data" do
  	  App.delete_all
  	  apps = App.get_all_apps
  	  expect(apps).not_to be_nil
  	  expect(apps.length).to eq 0
  	end
  end
end