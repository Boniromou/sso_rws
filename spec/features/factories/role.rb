FactoryGirl.define do
  factory :role do
    transient do
      with_permissions nil
    end

    after(:create) do |role, factory|
      if factory.with_permissions
        permissions = factory.with_permissions

        permissions.each do |permission|
          create(:role_permission, :role_id => role.id, :permission_id => permission.id)
        end
      end
    end
  end
end