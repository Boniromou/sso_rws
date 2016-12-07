require "feature_spec_helper"

describe SystemUsersController do
  fixtures :apps, :permissions, :role_permissions, :roles

  describe "[36] User management dashboard - view inactive system user" do
  	def create_inactive_user(casino_ids)
  		system_user = create(:system_user, status: false)
  		licensee = create(:licensee)
  		casino_ids.each do |casino_id|
        create(:casino, :id => casino_id, :licensee_id => licensee.id) unless Casino.exists?(:id => casino_id)
        create(:casinos_system_user, system_user_id: system_user.id, casino_id: casino_id, status: false)
      end
      system_user
  	end

  	def format_casinos(casino_id_names)
	    return '' if casino_id_names.blank?
	    rtn = ""
	    casino_id_names.each do |casino|
	      rtn += " [#{casino[:name]}, #{casino[:id]}]," 
	    end
	    rtn = rtn.chomp(',') 
	  end

  	def check_system_user_list(system_users)
  		expect(page.all("table#system_user tbody tr").count).to eq system_users.size
  		system_users.each_with_index do |system_user, index|
	  		within("table#system_user tbody tr:nth-child(#{index+1})") {
			  	expect_have_content("#{system_user.username}@#{system_user.domain.name}")
			  	expect_have_content(I18n.t("user.inactive"))
			  	expect(page).not_to have_content(format_casinos(system_user.casinos.as_json))
			  }
			end
  	end

    before(:each) do
      user_manager_role = Role.find_by_name "user_manager"
      @system_user_1 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1000])
      @system_user_2 = create(:system_user, :roles => [user_manager_role], :with_casino_ids => [1003])
      @system_user_3 = create_inactive_user([1003])
      @system_user_4 = create_inactive_user([1003, 1007])
    end

    it "[36.1] verify the inactive system user" do
      login("#{@system_user_1.username}@#{@system_user_1.domain.name}")
      visit user_management_root_path
      titles = [I18n.t("user.user_name"), I18n.t("user.status"), I18n.t("casino.title"), I18n.t("general.updated_at")]
      page.all('table#system_user thead tr th').each_with_index do |th, index|
        expect(th.text).to eq titles[index]
      end
      check_system_user_list([@system_user_3, @system_user_4])
    end

    it "[36.2] verify the inactive system non-1000 user" do
      mock_ad_account_profile(true, [1003])
      login("#{@system_user_2.username}@#{@system_user_2.domain.name}")
      visit user_management_root_path
      check_system_user_list([@system_user_3])
    end
  end
end