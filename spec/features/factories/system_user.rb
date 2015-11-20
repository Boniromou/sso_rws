FactoryGirl.define do
  factory :system_user do
    sequence(:username) { |n| "system_user_#{n}" }
    status    true
    admin     false

    before(:create) do |system_user|
      system_user.auth_source = AuthSource.first || create(:auth_source, :internal)
    end

    transient do
      with_property_ids nil
    end

    after(:create) do |system_user, factory|
      system_user.roles.each { |role| system_user.apps << role.app }

      if factory.with_property_ids
        property_ids = factory.with_property_ids

        property_ids.each do |property_id|
          create(:property, :id => property_id) unless Property.exists?(:id => property_id)
          create(:properties_system_user, system_user_id: system_user.id, property_id: property_id)
        end
      end
    end

    trait :admin do
      username  'portal.admin'
      admin     true
    end
  end
end