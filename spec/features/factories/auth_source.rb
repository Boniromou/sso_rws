FactoryGirl.define do
  factory :auth_source do
    sequence(:id)
    auth_type "AuthSourceLdap"
    name "Laxino LDAP"
    host "0.0.0.0"
    port 389
    account ''
    account_password ""
    base_dn "DC=test,DC=example,DC=com"
  end
end