require "rails_helper"

describe Role do

  # describe 'preset_roles' do
  #   it 'should return the pre-set roles' do
  #     roles = Role.all
  #     expect(roles.length).to eq(5)
  #     expect(roles[0][:name]).to eq('user_manager')
  #     expect(roles[1][:name]).to eq('system_operator')
  #     expect(roles[2][:name]).to eq('helpdesk')
  #     expect(roles[3][:name]).to eq('property_operator')
  #     expect(roles[4][:name]).to eq('auditor')
  #   end
  # end

  describe "test get_apps_roles" do
    fixtures :roles, :permissions, :role_permissions, :role_types
    
    def check_role_permission roles, roles_names, roles_permissions
      roles.each_with_index do |role, index|
        expect(role["name"]).to eq roles_names[index]
        expect(role["permissions"]).to eq roles_permissions[index]
      end
    end

    it "success" do
      app_roles = Role.get_apps_roles
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
      Role.delete_all
      roles = Role.get_apps_roles
      expect(roles).not_to be_nil
      expect(roles.length).to eq 0
    end
  end
end
