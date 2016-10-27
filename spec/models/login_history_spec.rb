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

  describe "test clean_login_history" do
    def create_login_history(sign_in_at)
      LoginHistory.create(system_user_id: 1, domain_id: 1, app_id: 1, sign_in_at: sign_in_at)
    end

    before(:each) do
      @his1 = create_login_history(Time.now)
      @his2 = create_login_history((Time.now - REMAIN_LOGIN_HISTORY_DAYS.days).end_of_day.utc)
      @his3 = create_login_history((Time.now - (REMAIN_LOGIN_HISTORY_DAYS - 1).days).beginning_of_day.utc)
      @his4 = create_login_history(Time.now - (REMAIN_LOGIN_HISTORY_DAYS + 1 ).days)
    end

    it "clean_login_history successfully" do
      LoginHistory.clean_login_history
      expect(LoginHistory.count).to eq 2
      expect(LoginHistory.where(id: @his1.id).blank?).to eq false
      expect(LoginHistory.where(id: @his2.id).blank?).to eq true
      expect(LoginHistory.where(id: @his3.id).blank?).to eq false
      expect(LoginHistory.where(id: @his4.id).blank?).to eq true
    end
  end
end