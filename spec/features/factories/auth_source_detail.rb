FactoryGirl.define do
  factory :auth_source_detail do
    sequence(:id)
    sequence(:name) { |n| "Laxino LDAP#{n}" }
    #data {"host": "192.1.1.1", "port": 389, "account": "test@example.com", "account_password": "cc123456", "base_dn": "DC=test,DC=example,DC=com", "admin_account": "admin@example.com", "admin_password": "cc123456"}
    factory :auth_source_detail_1 do
      data ({"host" => "10.10.5.11","port" => "1234","account" => "hill","account_password" => "Cc123456","base_dn" => "portal.admin","admin_account" => "hill","admin_password" => "Cc123456"})
    end
  end
end
