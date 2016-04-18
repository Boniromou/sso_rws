FactoryGirl.define do
  factory :licensee do
    sequence(:name) { |n| "laxino_#{n}" }
    sequence(:description) { |n| "#{n}.mo.laxino.com" }
  end
end