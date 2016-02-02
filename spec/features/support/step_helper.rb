module StepHelper
  def check_flash_message(msg, check_existenance=true)
    if check_existenance
      flash_msg = find("div#flash_message div#message_content")
      expect(flash_msg.text).to eq(msg)
    else
      flash_msg = first("div#flash_message div#message_content")
      if flash_msg
        expect(flash_msg.text).not_to eq(msg)
      else
        expect(flash_msg).to be_nil
      end
    end
  end

  def mock_ldap_query(account_status, property_ids)
    dn = account_status ? ["OU=Licensee"] : ["OU=Licensee,OU=Disabled Accounts"]
    memberof = property_ids.map { |property_id| "CN=#{property_id}iportal" }
    entry = [{ :distinguishedName => dn, :memberOf => memberof }]
    allow_any_instance_of(AuthSourceLdap).to receive(:search).and_return(entry)
  end

  def mock_ad_account_profile(status, property_ids)
    allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
    #allow(Rigi::Ldap).to receive(:retrieve_user_profile).and_return(:account_status => status, :groups => property_ids)
    mock_ldap_query(status, property_ids)
  end

  def mock_time_at_now(time_in_str)
    fake_time = Time.parse(time_in_str)
    allow(Time).to receive(:now).and_return(fake_time)
  end

  def login(username)
    allow_any_instance_of(AuthSourceLdap).to receive(:authenticate).and_return(true)
    visit login_path
    fill_in "system_user_username", :with => username
    click_button I18n.t("general.login")
  end

  def login_as_root
    root_user = SystemUser.find_by_admin(1) || SystemUser.create(:username => "portal.admin", :status => true, :admin => true, :auth_source_id => 1)
    login_as(root_user, :scope => :system_user)
  end

  def check_success_audit_log(audit_target, action_type, action, action_by, description=nil)
    al = AuditLog.first
    expect(al.audit_target).to eq audit_target
    expect(al.action_type).to eq action_type
    expect(al.action).to eq action
    expect(al.action_status).to eq("success")
    expect(al.action_error).to be_nil
    expect(al.session_id).not_to be_empty
    expect(al.ip).not_to be_empty
    expect(al.action_by).to eq action_by
    expect(al.action_at).to be_kind_of(Time)
    expect(al.description).to eq description
  end

  def check_fail_audit_log(audit_target, action_type, action, action_by, description=nil)
    al = AuditLog.first
    expect(al.audit_target).to eq audit_target
    expect(al.action_type).to eq action_type
    expect(al.action).to eq action
    expect(al.action_status).to eq("fail")
    expect(al.action_error).not_to be_nil
    expect(al.session_id).not_to be_empty
    expect(al.ip).not_to be_empty
    expect(al.action_by).to eq action_by
    expect(al.action_at).to be_kind_of(Time)
    expect(al.description).to eq description
  end

  def verify_unauthorized_request
    expect(current_path).to eq home_root_path
    check_flash_message I18n.t("flash_message.not_authorize")
  end

  def verify_authorized_request
    expect(current_path).not_to eq home_root_path
    check_flash_message(I18n.t("flash_message.not_authorize"), false)
  end

  def assert_dropdown_menu_item(text_label, check_existenance=true)
    dropdown_menu_selector = "header#header div.project-context ul.dropdown-menu"
    dropdown_menu = find(dropdown_menu_selector)
    if check_existenance
      expect(dropdown_menu).to have_content text_label
    else
      expect(dropdown_menu).not_to have_content text_label
    end
  end

  def assert_left_panel_item(text_label, check_existenance=true)
    left_panel_selector = "nav ul"
    left_panel = find(left_panel_selector)
    if check_existenance
      expect(left_panel).to have_content text_label
    else
      expect(left_panel).not_to have_content text_label
    end
  end

  def click_header_link(title)
    first('ul.dropdown-menu').find('a', :text => title).click
  end
end

RSpec.configure do |config|
  config.include StepHelper, type: :feature
end
