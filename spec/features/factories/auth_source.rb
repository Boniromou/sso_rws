FactoryGirl.define do
  factory :auth_source do
    id 1
    auth_type "AuthSourceLdap"
    name "Laxino LDAP"
    host "127.0.0.0"
    port 389
    account ''
    account_password ""
    base_dn "DC=test,DC=example,DC=com"
    attr_login "sAMAccountName"
    attr_firstname "givenName"
    attr_lastname "sN"
    attr_mail "mail"
    onthefly_register 1
    domain "test"

    trait :internal do
      id 1
      name "Laxino LDAP"
      is_internal true
    end

    trait :external do
      id  2
      name "EXT LDAP"
      is_internal false
    end
  end
end