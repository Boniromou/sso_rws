FactoryGirl.define do
  factory :system_user do
    sequence(:username) { |n| "system_user_#{n}" }
    status    true
    admin     false

    before(:create) do |system_user|
      system_user.auth_source = AuthSource.first || create(:auth_source)
    end

    after(:create) do |system_user|
      system_user.roles.each { |role| system_user.apps << role.app }
    end

    trait :admin do
      username  'portal.admin'
      admin     true
    end
  end
end