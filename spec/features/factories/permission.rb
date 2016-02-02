FactoryGirl.define do
  factory :permission do
    #before(:create) do |permission|
    #  permission.app = App.find_by_name('user_management') || create(:user_management_app)
    #end

    before(:save) do |permission|
      permission.name = permission.action
    end
  end
end