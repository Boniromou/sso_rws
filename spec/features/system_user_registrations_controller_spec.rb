require "feature_spec_helper"

describe SystemUserRegistrationsController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset! 
  end

  describe "[3] Self Registration" do
    before(:each) do
      @fake_auth_source_info =  {:auth_type=>"AuthSourceLdap", :name=>"Fake LDAP", :host=>"127.0.0.0", :port=>389, :account=>"test", :account_password=>"secret", :base_dn=>"DC=test,DC=example,DC=com", :attr_login=>"sAMAccountName", :attr_firstname=>"givenName", :attr_lastname=>"sN", :attr_mail=>"mail", :onthefly_register=>true, :domain=>"test"}
      @auth_source1 = AuthSource.create(@fake_auth_source_info)
      allow(AuthSource).to receive(:get_default_auth_source).and_return(@auth_source1)
    end

    after(:each) do
      @auth_source1.destroy
    end

    it "[3.1] Register Successful" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      visit '/register'
      fill_in "system_user_username", :with => 'test_user'
      fill_in "system_user_password", :with => 'secret'
      click_button I18n.t("general.sign_up")
      expect(page).to have_content I18n.t("alert.signup_completed")
      SystemUser.find_by_username('test_user').destroy
    end
    
    it "[3.2] Register fail with wrong password" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(false)
      visit '/register'
      fill_in "system_user_username", :with => 'test_user'
      fill_in "system_user_password", :with => 'secret'
      click_button I18n.t("general.sign_up")
      expect(page).to have_content I18n.t("alert.invalid_login")
    end

    it "[3.3] Register fail with wrong account" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(false)
      visit '/register'
      fill_in "system_user_username", :with => 'test_user'
      fill_in "system_user_password", :with => 'secret'
      click_button I18n.t("general.sign_up")
      expect(page).to have_content I18n.t("alert.invalid_login")
    end

    it "[3.4] Duplicated Registration" do
      allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
      test_user = SystemUser.create(:username => 'test_user', :auth_source_id => @auth_source1.id)
      visit '/register'
      fill_in "system_user_username", :with => 'test_user'
      fill_in "system_user_password", :with => 'secret'
      click_button I18n.t("general.sign_up")
      expect(page).to have_content I18n.t("alert.registered_account")
      test_user.destroy
    end
  end
end
