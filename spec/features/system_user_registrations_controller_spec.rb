require "feature_spec_helper"

describe SystemUserRegistrationsController do
  fixtures :apps, :permissions, :role_permissions, :roles, :auth_sources, :domains, :licensees, :casinos

  describe "[3] Self Registration" do

    def go_signup_page_and_register(username)
      visit new_system_user_registration_path
      fill_in "system_user_username", :with => username
      fill_in "system_user_password", :with => 'secret'
      click_button I18n.t("general.sign_up")
    end

    it "[3.1] Register Successful" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      mock_ad_account_profile(true, [1000])
      go_signup_page_and_register('test_user@example.com')
      expect(page).to have_content I18n.t("alert.signup_completed")
      system_user = SystemUser.find_by_username('test_user')
      casino_system_user_1000 = CasinosSystemUser.where(:casino_id => 1000, :system_user_id => system_user.id).first
      expect(system_user.status).to eq true
      expect(casino_system_user_1000.status).to eq true
    end
    
    it "[3.2] Register fail with wrong password" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(false)
      go_signup_page_and_register('test_user@example.com')
      expect(page).to have_content I18n.t("alert.invalid_login")
    end

    it "[3.3] Register fail with wrong account" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(false)
      go_signup_page_and_register('test_user@example.com')
      expect(page).to have_content I18n.t("alert.invalid_login")
    end

    it "[3.4] Duplicated Registration" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      domain = Domain.where(:name => 'example.com').first
      test_user = create(:system_user, :username => 'test_user', :domain_id => domain.id, :licensee_id => Licensee.first.id)
      go_signup_page_and_register('test_user@example.com')
      expect(page).to have_content I18n.t("alert.registered_account")
    end

    it "[3.11] Register system user fail with AD property not match with MDS" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      mock_ad_account_profile(true, [1100])
      go_signup_page_and_register('test_user@example.com')
      expect(page).to have_content I18n.t("alert.account_no_property")
    end

    it "[3.12] Register system user fail with null property in AD." do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      mock_ad_account_profile(true, [])
      go_signup_page_and_register('test_user@example.com')
      expect(page).to have_content I18n.t("alert.account_no_property")
    end

    it "[3.13] Register user with upper case." do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      mock_ad_account_profile(true, [1000])
      go_signup_page_and_register('TEST_USER@EXAMPLE.COM')
      expect(page).to have_content I18n.t("alert.signup_completed")
      system_user = SystemUser.find_by_username('test_user')
      casino_system_user_1000 = CasinosSystemUser.where(:casino_id => 1000, :system_user_id => system_user.id).first
      expect(system_user.status).to eq true
      expect(casino_system_user_1000.status).to eq true      
    end
  end

  describe "[1] Login/Logout" do
    before(:each) do
      @registered_account = create(:system_user, :username => 'test_user', :status => true, :with_casino_ids => [1000], :domain_id => Domain.first.id, :licensee_id => Licensee.first.id)
    end

    it "[1.7] unexpected login (click login link)" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      visit '/register'
      fill_in "system_user_username", :with => "#{@registered_account.username}@#{@registered_account.domain.name}"
      fill_in "system_user_password", :with => 'secret'
      click_button I18n.t("general.sign_up")
      expect(page).to have_content I18n.t("alert.registered_account")
      click_link I18n.t("general.login")
      expect(current_path).to eq login_path
    end

    it "[1.8] unexpected login (click register)" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      visit '/register'
      fill_in "system_user_username", :with => "#{@registered_account.username}@#{@registered_account.domain.name}"
      fill_in "system_user_password", :with => 'secret'
      click_button I18n.t("general.sign_up")
      expect(page).to have_content I18n.t("alert.registered_account")
      fill_in "system_user_username", :with => "#{@registered_account.username}@#{@registered_account.domain.name}"
      fill_in "system_user_password", :with => 'secret'
      click_button I18n.t("general.sign_up")
      expect(current_path).to eq register_path
      expect(page).to have_content I18n.t("alert.registered_account")
    end
  end
end
