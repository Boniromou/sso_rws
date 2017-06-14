require "feature_spec_helper"

describe RolesController do
  fixtures :apps, :permissions, :role_permissions, :roles, :auth_sources

  before(:each) do
    @root_user = create(:system_user, :admin, :with_casino_ids => [1000])
  end

  def go_to_role_and_permission
    visit '/home'
    click_header_link(I18n.t("header.role_management"))
    click_link('Role and Permission')
  end

  describe "[15] List Role & Permission" do
    before(:each) do
      user_manager_role = Role.find_by_name "user_manager"
      @system_user_1 = create(:system_user, :roles => [user_manager_role])
      mock_ad_account_profile
    end

    it "[15.3] Show Role (authorized)" do
      allow_any_instance_of(RolePolicy).to receive("index?").and_return(true)
      allow_any_instance_of(PermissionPolicy).to receive("show?").and_return(false)
      login("#{@root_user.username}@#{@root_user.domain.name}")
      go_to_role_and_permission
      role_table_selector = "div#content div#user_management"
      expect(find("#{role_table_selector} header")).to have_content("User Management")
      expect(find("#{role_table_selector}")).to have_content("User Manager")
      expect(find("#{role_table_selector}")).to_not have_link(I18n.t("role.show_permission"))
      expect(find('a#exportRolePermission').text).to eq I18n.t("general.export")
      logout(@root_user)
    end

    it "[15.4] Show Role (unauthorized)" do
      allow_any_instance_of(RolePolicy).to receive("index?").and_return(false)
      allow_any_instance_of(PermissionPolicy).to receive("show?").and_return(false)
      login("#{@root_user.username}@#{@root_user.domain.name}")
      visit home_root_path
      assert_dropdown_menu_item(I18n.t("header.role_management"), false)
      logout(@root_user)
    end

    it "[15.5] Show Permission (authorized)" do
      allow_any_instance_of(RolePolicy).to receive("index?").and_return(true)
      allow_any_instance_of(PermissionPolicy).to receive("show?").and_return(true)
      login("#{@root_user.username}@#{@root_user.domain.name}")
      go_to_role_and_permission
      role_table_selector = "div#content div#user_management"
      expect(find("#{role_table_selector} header")).to have_content("User Management")
      expect(find("#{role_table_selector}")).to have_content("User Manager")
      expect(find("#{role_table_selector}")).to have_link(I18n.t("role.show_permission"))
      find("#{role_table_selector}").first('a', :text => I18n.t("role.show_permission")).click
      expect(find("div#content div#show_permission")).to have_content(I18n.t("role.permissions"))
      logout(@root_user)
    end
  end

  describe "[27] Export permission list" do
    it "[27.1] successfully export", :js => true do
      login("#{@root_user.username}@#{@root_user.domain.name}")
      visit roles_path
      expect(find('a#exportRolePermission').text).to eq I18n.t("general.export")
      expect(page.has_css?('div#pop_up_dialog', visible: false)).to eq true
      page.find("#exportRolePermission").click
      expect(page.has_css?('div#pop_up_dialog', visible: true)).to eq true
      expect(find("div#pop_up_content").text).to eq I18n.t("confirm.export_role_permission")
      find("button#confirm").click
      expect(page.has_css?('div#pop_up_dialog', visible: false)).to eq true
    end
  end
end
