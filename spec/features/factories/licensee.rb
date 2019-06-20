FactoryGirl.define do
  factory :licensee do
    sequence(:name) { |n| "laxino_#{n}" }
    sequence(:description) { |n| "#{n}.mo.laxino.com" }
    timezone "Asia/Macao"

    transient do
      with_domain nil
      with_casino_ids nil
    end

    after(:create) do |licensee, factory|
      if factory.with_domain
        auth_source_detail = create(:auth_source_detail, :name => 'test', :data => {})
        domain = Domain.find_by_name(factory.with_domain) || create(:domain, name: factory.with_domain, auth_source_detail_id: auth_source_detail.id)
        create(:domain_licensee, domain_id: domain.id, licensee_id: licensee.id)
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
