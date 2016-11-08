FactoryGirl.define do
  factory :domain do
  	sequence(:name) { |n| "#{n}.mo.laxino.com" }

    transient do
      with_licensee false
    end

  	before(:create) do |domain, evaluator|
      with_licensee = evaluator.with_licensee
      if with_licensee
      	licensee = create(:licensee, :with_casino_ids => [1000, 1003, 1007])
      	domain.licensee_id = licensee.id
      end
    end
  end
end