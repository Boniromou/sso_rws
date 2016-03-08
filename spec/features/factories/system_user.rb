FactoryGirl.define do
  factory :system_user do
    sequence(:username) { |n| "system_user_#{n}" }
    status    true
    admin     false
    #domain  'example.com'
    domain_id 1

    before(:create) do |system_user|
      system_user.auth_source = AuthSource.first || create(:auth_source, :internal)
    end

    transient do
      with_casino_ids nil
      licensee_id nil
    end

    after(:create) do |system_user, factory|
      system_user.roles.each { |role| system_user.apps << role.app }

      if factory.with_casino_ids
        casino_ids = factory.with_casino_ids

        casino_ids.each do |casino_id|
          create(:casino, :id => casino_id, :licensee_id => factory.licensee_id, :name => 'laxino'+"#{casino_id}") unless Casino.exists?(:id => casino_id)
          create(:casinos_system_user, system_user_id: system_user.id, casino_id: casino_id)
        end
      end
    end

    trait :admin do
      username  'portal.admin'
      admin     true
    end
  end
end
