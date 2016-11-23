FactoryGirl.define do
  factory :system_user do
    sequence(:username) { |n| "system_user_#{n}" }
    status    true
    admin     false

    transient do
      with_casino_ids nil
      with_roles nil
      domain_name "example.com"
    end

    before(:create) do |system_user, factory|
      auth_source = create(:auth_source)
      domain = Domain.find_by_name(factory.domain_name) || create(:domain, name: factory.domain_name, auth_source_id: auth_source.id)
      system_user.auth_source = domain.auth_source
      system_user.domain_id = domain.id
    end



    after(:create) do |system_user, factory|
      system_user.roles = factory.with_roles if factory.with_roles
      system_user.roles.each { |role| system_user.apps << role.app }

      if factory.with_casino_ids
        casino_ids = factory.with_casino_ids
        licensee = create(:licensee, domain_id: system_user.domain.id)
        casino_ids.each do |casino_id|
          create(:casino, :id => casino_id, :licensee_id => licensee.id) unless Casino.exists?(:id => casino_id)
          create(:casinos_system_user, system_user_id: system_user.id, casino_id: casino_id) unless CasinosSystemUser.exists?(:system_user_id => system_user.id, :casino_id => casino_id)
        end
      end
    end

    trait :admin do
      username  'portal.admin'
      admin     true
    end
  end
end
