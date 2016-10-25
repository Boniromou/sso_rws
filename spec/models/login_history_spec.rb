require "rails_helper"

describe LoginHistory do
  describe "test validate" do
    it "system_user_id, domain_id, app_id, sign_in_at cannot be null" do
      attrs = ['system_user_id', 'domain_id', 'app_id', 'sign_in_at']
      count = LoginHistory.count
      login_history = LoginHistory.new
      login_history.save
      attrs.each do |att|
        expect(login_history.errors[att.to_sym]).to include("can't be blank")
      end
      expect(LoginHistory.count).to eq count
    end
  end

  describe "test insert" do
    before(:each) do
      @params = {}
      @params[:system_user_id] = 1
      @params[:domain_id] = 1
      @params[:app_id] = 1
      @params[:detail] = {:casino_ids => [1000], :casino_id_name => [{:id => 1000, :name => 'LAXINO'}]}
    end

    it "insert successfully" do
      count = LoginHistory.count
      login_history = LoginHistory.insert(@params)
      expect(LoginHistory.count).to eq count + 1
    end

    it "insert failed: system_user_id is nil" do
      @params.delete(:system_user_id)
      count = LoginHistory.count
      flag = false
      begin
        login_history = LoginHistory.insert(@params)
      rescue ActiveRecord::RecordInvalid
        flag = true
      end
      expect(flag).to eq true
      expect(LoginHistory.count).to eq count
    end
  end
end