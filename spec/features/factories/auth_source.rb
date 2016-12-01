FactoryGirl.define do
  factory :auth_source do
    sequence(:id)
    auth_type "AuthSourceLdap"
    sequence(:name) { |n| "Laxino LDAP#{n}" }
    host "0.0.0.0"
    port 389
    account "test@example.com"
    account_password "cc123456"
    base_dn "DC=test,DC=example,DC=com"
    admin_account "admin@example.com"
    admin_password "cc123456"
  end
end