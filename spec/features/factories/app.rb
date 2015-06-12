FactoryGirl.define do
  factory :user_management_app, class: App do
    id   1
    name "user_management"
  end

  factory :gaming_operation_app, class: App do
    id   2
    name "gaming_operation"
  end

  factory :cage_app, class: App do
    id   3
    name "cage"
  end
end