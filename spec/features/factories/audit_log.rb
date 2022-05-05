FactoryGirl.define do
  factory :audit_log do
    #audit_target "maintenance"
    #action "create"
    action_type "create"
    action_by "portal.admin"
    action_at Time.now
    session_id "2838f8b6ff972453eabe1367485986b1"
    ip "127.0.0.1"
    description ""

    trait :success do
      action_error ""
      action_status "success"
    end

    trait :fail do
      action_error "mock error"
      action_status "fail"
    end

    after(:create) do |audit_log|
      audit_log.created_at = audit_log.action_at
      audit_log.updated_at = audit_log.action_at
    end
  end
end