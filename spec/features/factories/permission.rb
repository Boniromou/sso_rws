FactoryGirl.define do
  factory :permission do
    before(:create) do |permission|
      permission.app = App.find_by_name('user_management') || create(:user_management_app)
    end
  end
end