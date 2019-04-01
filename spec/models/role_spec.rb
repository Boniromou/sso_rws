require "rails_helper"

describe Role do

  describe "test validate" do
    it "role name cannot be null" do
      count = Role.count
      role = Role.new
      role.app_id = 1
      role.role_type_id = 1
      role.save
      expect(role.errors[:name]).to include("can't be blank")
      expect(Role.count).to eq count
    end
  end

  describe "test get_apps_roles" do
    fixtures :roles, :permissions, :role_permissions, :role_types

    def check_role_permission roles, roles_names, roles_permissions
      roles.each_with_index do |role, index|
        expect(role["name"]).to eq roles_names[index]
        expect(role["permissions"]).to eq roles_permissions[index]
      end
    end

    it "success" do
      app_roles = Role.get_apps_roles(Role.all)
      expect(app_roles.length).to eq 3

      roles_1 = app_roles[1]
      roles_2 = app_roles[2]
      roles_3 = app_roles[3]

      roles_1_names = ["User Manager [Int.]","Auditor [Int.]","It Support [Ext.]"]
      roles_1_permissions = [[2, 3, 4, 5],[1],[29, 30]]
      check_role_permission(roles_1, roles_1_names, roles_1_permissions)

      roles_2_names = ["Change Coordinator [Int.]",
                       "Service Desk Manager [Int.]",
                       "Service Desk Agent [Int.]",
                       "Property Operator [Int.]",
                       "System Auditor [Int.]"]
      roles_2_permissions = [[9, 15],
                             [1, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24],
                             [8, 9, 10, 11, 12, 13, 14,15, 16, 17, 18, 19, 20, 21, 22],
                             [],
                             [1]]
      check_role_permission(roles_2, roles_2_names, roles_2_permissions)

      roles_3_names = ["Cashier [Int.]"]
      roles_3_permissions = [[25, 26, 27, 28]]
      check_role_permission(roles_3, roles_3_names, roles_3_permissions)
    end

    it "roles no data" do
      RolePermission.delete_all
      Role.delete_all
      roles = Role.get_apps_roles(Role.all)
      expect(roles).not_to be_nil
      expect(roles.length).to eq 0
    end
  end
end
