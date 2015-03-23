module StepHelper
  def check_flash_message(msg)
    flash_msg = find("div#flash_message div#message_content")
    expect(flash_msg.text).to eq(msg)
  end

  def mock_time_at_now(time_in_str)
    fake_time = Time.parse(time_in_str)
    allow(Time).to receive(:now).and_return(fake_time)
  end

  def login_as_root
    root_user = SystemUser.find_by_admin(1)
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
end

RSpec.configure do |config|
  config.include StepHelper, type: :feature
end
