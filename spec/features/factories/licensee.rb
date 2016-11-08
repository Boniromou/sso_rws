FactoryGirl.define do
  factory :licensee do
    sequence(:name) { |n| "laxino_#{n}" }
    sequence(:description) { |n| "#{n}.mo.laxino.com" }

    transient do
      with_casino_ids nil
    end

    after(:create) do |licensee, evaluator|
    	casino_ids = evaluator.with_casino_ids
      if casino_ids
        casino_ids.each do |casino_id|
          casino = Casino.find_by_id(casino_id)
          if !casino
            create(:casino, :id => casino_id, :licensee_id => licensee.id)
          elsif casino.licensee_id != licensee.id
            casino.update_attributes(licensee_id: licensee.id)
          end
        end
      end
    end
  end
end