FactoryGirl.define do
  factory :domain do
  	sequence(:name) { |n| "#{n}.mo.laxino.com" }

    transient do
      with_casino_ids nil
    end

    after(:create) do |domain, evaluator|
      casino_ids = evaluator.with_casino_ids
      if casino_ids
        licensee = create(:licensee)
        create(:domain_licensee, domain_id: domain.id, licensee_id: licensee.id)
        casino_ids.each do |casino_id|
          create(:casino, :id => casino_id, :licensee_id => licensee.id) unless Casino.exists?(:id => casino_id)
        end
      end
    end
  end
end