FactoryGirl.define do
  factory :system_user do
    sequence(:username) { |n| "system_user_#{n}" }
    status    true
    admin     false

    before(:create) do |system_user|
      system_user.auth_source = AuthSource.first || create(:auth_source, :internal)
      domain = Domain.find_by_name("example.com") || create(:domain, name: "example.com")
      system_user.domain_id = domain.id
    end

    transient do
      with_casino_ids nil
      with_roles nil
    end

    after(:create) do |system_user, factory|
      system_user.roles = factory.with_roles if factory.with_roles

      system_user.roles.each { |role| system_user.apps << role.app }

      if factory.with_casino_ids
        casino_ids = factory.with_casino_ids
        licensee = Licensee.find_by_name("laxino") || create(:licensee, name: "laxino")
        casino_ids.each do |casino_id|
          create(:casino, :id => casino_id, :licensee_id => licensee.id) unless Casino.exists?(:id => casino_id)
          create(:casinos_system_user, system_user_id: system_user.id, casino_id: casino_id) unless CasinosSystemUser.exists?(:system_user_id => system_user.id, :casino_id => casino_id)
          create(:domains_casino, domain_id: system_user.domain_id, casino_id: casino_id) unless DomainsCasino.exists?(:domain_id => system_user.domain_id, :casino_id => casino_id)
        end
      end
    end

    trait :admin do
      username  'portal.admin'
      admin     true
    end
  end
end
