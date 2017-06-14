require "feature_spec_helper"

describe SystemUserRegistrationsController do
  def create_casinos_with_licensee(casino_ids, licensee_id)
    casino_ids.each do |casino_id|
      create(:casino, :id => casino_id, :licensee_id => licensee_id)
    end
  end
  
  # describe "[3] Self Registration" do
  #   before(:each) do
  #     mock_authenticate
  #     auth_source = create(:auth_source)
  #     domain = create(:domain, :name => "example.com", :auth_source_id => auth_source.id)
  #     licensee = create(:licensee, :domain_id => domain.id)
  #     create_casinos_with_licensee([1000, 1003, 1007], licensee.id)
      
  #     create(:domain, :name => "invalid.ldap.com")
  #   end

  #   def go_signup_page_and_register(username)
  #     visit new_system_user_registration_path
  #     fill_in "system_user_username", :with => username
  #     fill_in "system_user_password", :with => 'secret'
  #     click_button I18n.t("general.sign_up")
  #   end

  #   it "[3.1] Register Successful" do
  #     mock_ad_account_profile(true, [1000])
  #     go_signup_page_and_register('test_user@example.com')
  #     expect(page).to have_content I18n.t("alert.signup_completed")
  #     system_user = SystemUser.find_by_username('test_user')
  #     casino_system_user_1000 = CasinosSystemUser.where(:casino_id => 1000, :system_user_id => system_user.id).first
  #     expect(system_user.status).to eq true
  #     expect(casino_system_user_1000.status).to eq true
  #   end

  #   it "[3.2] Register fail with wrong password" do
  #     mock_authenticate(false)
  #     go_signup_page_and_register('test_user@example.com')
  #     expect(page).to have_content I18n.t("alert.invalid_login")
  #   end

  #   it "[3.3] Register fail with wrong account" do
  #     mock_authenticate(false)
  #     go_signup_page_and_register('test_user@example.com')
  #     expect(page).to have_content I18n.t("alert.invalid_login")
  #   end

  #   it "[3.4] Duplicated Registration" do
  #     allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
  #     test_user = create(:system_user, :username => 'test_user')
  #     go_signup_page_and_register('test_user@example.com')
  #     expect(page).to have_content I18n.t("alert.registered_account")
  #   end

  #   it "[3.11] Register system user fail with AD casino not match with MDS" do
  #     mock_ad_account_profile(true, [1100])
  #     go_signup_page_and_register('test_user@example.com')
  #     expect(page).to have_content I18n.t("alert.account_no_casino")
  #   end

  #   it "[3.12] Register system user fail with null casino in AD." do
  #     mock_ad_account_profile(true, [])
  #     go_signup_page_and_register('test_user@example.com')
  #     expect(page).to have_content I18n.t("alert.account_no_casino")
  #   end

  #   it "[3.13] Register user with upper case." do
  #     mock_ad_account_profile(true, [1000])
  #     go_signup_page_and_register('TEST_USER@EXAMPLE.COM')
  #     expect(page).to have_content I18n.t("alert.signup_completed")
  #     system_user = SystemUser.find_by_username('test_user')
  #     casino_system_user_1000 = CasinosSystemUser.where(:casino_id => 1000, :system_user_id => system_user.id).first
  #     expect(system_user.status).to eq true
  #     expect(casino_system_user_1000.status).to eq true
  #   end

  #   it "[3.14] Register with incorrect domain" do
  #     mock_ad_account_profile(true, [1000])
  #     go_signup_page_and_register('test_user@other.com')
  #     expect(page).to have_content I18n.t("alert.invalid_login")
  #   end

  #   it "[3.16] Register system user fail with auth_source-licensee mapping not exist" do
  #     mock_ad_account_profile(true, [1000])
  #     go_signup_page_and_register('test_user@invalid.ldap.com')
  #     expect_have_content_downcase(I18n.t("alert.invalid_ldap_mapping"), '.')
  #   end
  # end

  # describe "[1] Login/Logout" do
  #   fixtures :apps, :permissions, :role_permissions, :roles

  #   before(:each) do
  #     mock_authenticate
  #     auth_source = create(:auth_source)
  #     domain = create(:domain, :name => "example.com", :auth_source_id => auth_source.id)
  #     licensee = create(:licensee, :domain_id => domain.id)
  #     create_casinos_with_licensee([1000, 1001, 1002, 1003], licensee.id)
  #     @registered_account = create(:system_user, :username => 'test_user', :status => true, :with_casino_ids => [1000])
  #   end

  #   it "[1.7] unexpected login (click login link)" do
  #     visit '/register'
  #     fill_in "system_user_username", :with => "#{@registered_account.username}@#{@registered_account.domain.name}"
  #     fill_in "system_user_password", :with => 'secret'
  #     click_button I18n.t("general.sign_up")
  #     expect(page).to have_content I18n.t("alert.registered_account")
  #     click_link I18n.t("general.login")
  #     expect(current_path).to eq login_path
  #   end

  #   it "[1.8] unexpected login (click register)" do
  #     visit '/register'
  #     fill_in "system_user_username", :with => "#{@registered_account.username}@#{@registered_account.domain.name}"
  #     fill_in "system_user_password", :with => 'secret'
  #     click_button I18n.t("general.sign_up")
  #     expect(page).to have_content I18n.t("alert.registered_account")
  #     fill_in "system_user_username", :with => "#{@registered_account.username}@#{@registered_account.domain.name}"
  #     fill_in "system_user_password", :with => 'secret'
  #     click_button I18n.t("general.sign_up")
  #     expect(current_path).to eq register_path
  #     expect(page).to have_content I18n.t("alert.registered_account")
  #   end
  # end

  # describe "[33] Reset password" do
  #   fixtures :apps, :permissions, :role_permissions, :roles

  #   def mock_reset_password(rtn=true)
  #     allow_any_instance_of(AuthSourceLdap).to receive(:reset_password!).and_return(rtn)
  #   end

  #   def goto_reset_password_and_update(username=nil, new_password='newsecret', password_confirm=nil)
  #     username = username || "#{@root_user.username}@#{@root_user.domain.name}"
  #     visit edit_system_user_passwords_path(app_name: APP_NAME)
  #     fill_in 'system_user_username', :with => username
  #     fill_in 'system_user_old_password', :with => 'secret'
  #     fill_in 'system_user_new_password', :with => new_password
  #     fill_in 'system_user_password_confirmation', :with => password_confirm || new_password
  #     click_button I18n.t("password_page.update_password")
  #   end

  #   before(:each) do
  #     mock_reset_password
  #     @root_user = create(:system_user, :admin, :with_casino_ids => [1000])
  #     @user_manager_role = Role.find_by_name "user_manager"
  #   end

  #   it "[33.1] Reset password successful" do
  #     goto_reset_password_and_update
  #     expect(page.current_path).to eq edit_system_user_passwords_path
  #     expect_have_content(I18n.t("success.reset_password").titleize)
  #   end

  #   it "[33.2] Reset password fail with wrong password" do
  #     mock_authenticate(false)
  #     goto_reset_password_and_update
  #     expect_have_content(I18n.t("alert.invalid_login"))
  #   end

  #   it "[33.3] Reset password fail with wrong account" do
  #     goto_reset_password_and_update("wrong_username@wrong.domain.com")
  #     expect_have_content(I18n.t("alert.invalid_login"))
  #   end

  #   it "[33.4] Reset password without role assigned" do
  #     system_user = create(:system_user, :with_casino_ids => [1003])
  #     goto_reset_password_and_update("#{system_user.username}@#{system_user.domain.name}")
  #     expect_have_content(I18n.t("alert.account_no_role"))
  #   end

  #   it "[33.6] Reset password fail with user AD casino group null" do
  #     system_user = create(:system_user, :roles => [@user_manager_role], :with_casino_ids => [1003])
  #     mock_ad_account_profile(true, [])
  #     goto_reset_password_and_update("#{system_user.username}@#{system_user.domain.name}")
  #     casino_system_user_1003 = CasinosSystemUser.where(:casino_id => 1003, :system_user_id => system_user.id).first
  #     expect(casino_system_user_1003.status).to eq false
  #     expect_have_content(I18n.t("alert.account_no_casino"))
  #   end

  #   it "[33.7] Reset password fail  and update the User active/inactive status" do
  #     system_user = create(:system_user, :roles => [@user_manager_role], :with_casino_ids => [1003])
  #     mock_ad_account_profile(false, [])
  #     goto_reset_password_and_update("#{system_user.username}@#{system_user.domain.name}")
  #     system_user.reload
  #     expect(system_user.status).to eq false
  #     expect_have_content(I18n.t("alert.inactive_account"))
  #   end

  #   it "[33.8] Reset password user with upper case" do
  #     system_user = create(:system_user, :roles => [@user_manager_role], :with_casino_ids => [1003])
  #     mock_ad_account_profile(true, [1003])
  #     goto_reset_password_and_update("#{system_user.username.upcase}@#{system_user.domain.name}")
  #     expect(page.current_path).to eq edit_system_user_passwords_path
  #     expect_have_content(I18n.t("success.reset_password").titleize)
  #   end

  #   it "[33.9] Reset password fail with AD casino not match with local" do
  #     system_user = create(:system_user, :roles => [@user_manager_role], :with_casino_ids => [1003])
  #     mock_ad_account_profile(true, [1007])
  #     goto_reset_password_and_update("#{system_user.username.upcase}@#{system_user.domain.name}")
  #     expect_have_content(I18n.t("alert.account_no_casino"))
  #   end

  #   it "[33.11] Reset password fail with auth_source - domain mapping not exist" do
  #     system_user = create(:system_user, :roles => [@user_manager_role], :with_casino_ids => [1003])
  #     domain = system_user.domain
  #     domain.auth_source_id = nil
  #     domain.save!
  #     mock_ad_account_profile(true, [1003])
  #     goto_reset_password_and_update("#{system_user.username}@#{system_user.domain.name}")
  #     expect_have_content_downcase(I18n.t("alert.invalid_ldap_mapping"), '.')
  #   end

  #   it "[33.12] Confirm new password fail" do
  #     goto_reset_password_and_update(nil, 'new_password', 'wrong_password_confirm')
  #     expect_have_content_downcase(I18n.t("password_page.confirm_password_fail"), '.')
  #   end

  #   it "[33.13] Reset password fail with illegal new password format" do
  #     allow_any_instance_of(AuthSourceLdap).to receive(:reset_password!).and_raise(Rigi::InvalidResetPassword.new("password format error"))
  #     goto_reset_password_and_update(nil, '0000')
  #     expect_have_content_downcase("password format error")
  #   end

  #   it "Reset password fail with new password is nil" do
  #     goto_reset_password_and_update(nil, nil)
  #     expect_have_content_downcase(I18n.t("password_page.invalid_password_format"), '.')
  #   end

  #   it "Reset password fail with app is nil" do
  #     visit edit_system_user_passwords_path
  #     click_button I18n.t("password_page.update_password")
  #     expect_have_content_downcase(I18n.t("password_page.invalid_system"))
  #   end
  # end
end
