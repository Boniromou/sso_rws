FactoryGirl.define do
  factory :domain do
  	sequence(:name) { |n| "#{n}.mo.laxino.com" }
  end
end