require "rails_helper"

describe Permission do
  def create_permissions(targets, app_id)
    targets.each do |target|
      (0..2).each do |index|
        create(:permission, target: target, action: "target_#{index}", name: "name_#{index}", app_id: app_id)
      end
    end
  end
  
  before(:each) do
    app1 = create(:app, name: APP_NAME)
    app2 = create(:app, name: 'gaming_operation')
    app3 = create(:app, name: 'cage')
    create_permissions(['system_user'], app1.id)
    create_permissions(['audit_log', 'maintenance', 'test_player'], app2.id)
    create_permissions(['player', 'player_transaction'], app3.id)
  end
  
  describe "test validate" do
    it "permission name,action,target cannot be null" do
      count = Permission.count
      permission = Permission.new
      permission.save
      expect(permission.errors[:name]).to include("can't be blank")
      expect(permission.errors[:action]).to include("can't be blank")
      expect(permission.errors[:target]).to include("can't be blank")
      expect(Permission.count).to eq count
    end
  end

  describe "test get_all_permissions" do
    def check_permissions app_id, target_permissions, targets
      expect(target_permissions.length).to eq targets.length
      targets.each do |target|
        fixture_permissions = Permission.where("app_id = #{app_id} and target = '#{target}'").pluck(:id)
        permissions = target_permissions[target]
        expect(permissions.length).to eq fixture_permissions.length
        expect(permissions.map(&:id)).to eq fixture_permissions
      end
    end

  	it "success" do
  	  app_permissions = Permission.get_all_permissions
  	  expect(app_permissions.length).to eq 3
      target_permissions_1 = app_permissions[1]
      target_permissions_2 = app_permissions[2]
      target_permissions_3 = app_permissions[3]
      targets_1 = ['system_user']
      check_permissions(1, target_permissions_1, targets_1)
      targets_2 = ['audit_log', 'maintenance', 'test_player']
      check_permissions(2, target_permissions_2, targets_2)
      targets_3 = ['player', 'player_transaction']
      check_permissions(3, target_permissions_3, targets_3)
  	end

  	it "permissions no data" do
  	  Permission.delete_all
      app_permissions = Permission.get_all_permissions
  	  expect(app_permissions).not_to be_nil
  	  expect(app_permissions.length).to eq 0
  	end
  end
end