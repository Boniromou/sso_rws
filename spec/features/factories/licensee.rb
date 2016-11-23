FactoryGirl.define do
  factory :licensee do
    sequence(:name) { |n| "laxino_#{n}" }
    sequence(:description) { |n| "#{n}.mo.laxino.com" }

    transient do
      with_domain nil
      with_casino_ids nil
    end

    before(:create) do |licensee, factory|
      if factory.with_domain
        auth_source = create(:auth_source)
      	domain = Domain.find_by_name(factory.with_domain) || create(:domain, name: factory.with_domain, auth_source_id: auth_source.id)
        licensee.domain_id = domain.id
      end
    end

    after(:create) do |licensee, factory|
      casino_ids = factory.with_casino_ids
      if casino_ids
        casino_ids.each do |casino_id|
          create(:casino, :id => casino_id, :licensee_id => licensee.id) unless Casino.exists?(:id => casino_id, :licensee_id => licensee.id)
        end
      end
    end
  end
end