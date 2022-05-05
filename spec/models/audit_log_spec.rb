require "rails_helper"

describe AuditLog do
  describe "#system_user_log" do
    it 'should create an audit log for system_user correctly' do
      AuditLog.system_user_log("system_user", "create", "portal.admin", "qwer1234", "127.0.0.1", { :action_at => Time.now })
      al = AuditLog.first
      expect(al.audit_target).to eq("system_user")
      expect(al.action_type).to eq("create")
      expect(al.action).to eq("create")
      expect(al.action_status).to eq("success")
      expect(al.action_error).to be_nil 
      expect(al.session_id).to eq("qwer1234")
      expect(al.ip).to eq("127.0.0.1")
      expect(al.action_by).to eq("portal.admin")
      expect(al.action_at).to be_kind_of(Time)
      expect(al.description).to be_nil
    end
  end
  
  describe "audit error message" do
    it 'should create an audit log if the action to audit raises an exception' do
      expect { 
        AuditLog.system_user_log("system_user", "create", "portal.admin", "qwer1234", "127.0.0.1", { :action_at => Time.now }) do
          raise "mock exception"
        end
      }.to raise_error
      al = AuditLog.first
      expect(al.audit_target).to eq("system_user")
      expect(al.action_type).to eq("create")
      expect(al.action).to eq("create")
      expect(al.action_status).to eq("fail")
      expect(al.action_error).to eq("mock exception") 
      expect(al.session_id).to eq("qwer1234")
      expect(al.ip).to eq("127.0.0.1")
      expect(al.action_by).to eq("portal.admin")
      expect(al.action_at).to be_kind_of(Time)
      expect(al.description).to be_nil
    end
  end
end
