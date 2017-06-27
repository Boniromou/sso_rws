require "rails_helper"

describe RoleType do
  describe "test get_all_role_types" do
    before(:each) do
      @role_type1 = create(:role_type, name: 'internal')
      @role_type2 = create(:role_type, name: 'external')
    end

  	it "success" do
  	  role_types = RoleType.get_all_role_types
  	  expect(role_types.length).to eq 2
      expect(role_types[@role_type1.id]).to eq I18n.t("role_type.internal")
      expect(role_types[@role_type2.id]).to eq I18n.t("role_type.external")
  	end

  	it "role_types no data" do
      RoleType.delete_all
  	  role_types = RoleType.get_all_role_types
  	  expect(role_types).not_to be_nil
  	  expect(role_types.length).to eq 0
  	end
  end
end