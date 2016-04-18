FactoryGirl.define do
  factory :casino do
    sequence(:name) { |n| "casino#{n}" }
    licensee
  end
end