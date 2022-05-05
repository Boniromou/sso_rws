FactoryGirl.define do
  factory :login_history do
  	sign_in_at Time.now.utc

    transient do
      user_casino_ids [1000]
      app_name "user_management"
    end

  	before(:create) do |history, evaluator|
      casino_ids = evaluator.user_casino_ids
      app_name = evaluator.app_name
      system_user = create(:system_user, :with_casino_ids => casino_ids)
      history.system_user_id = system_user.id
      history.domain_id = system_user.domain_id
      app = App.find_by_name(app_name) || create(:app, :name => app_name)
      history.app_id = app.id
      casino_id_names = casino_ids.map{|casino_id| {:id => casino_id, :name => Casino.find(casino_id).name}}
      history.detail = {:casino_ids => casino_ids, :casino_id_names => casino_id_names}
    end
  end
end