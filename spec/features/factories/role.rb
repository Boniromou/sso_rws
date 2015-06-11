FactoryGirl.define do
  factory :role do
  end

  trait :user_management_app do
    user_management_app
  end

  trait :gaming_operation_app do
    gaming_operation_app
  end

  trait :cage_app do
    cage_app
  end
end