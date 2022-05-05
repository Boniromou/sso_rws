FactoryGirl.define do
  factory :property do
    sequence(:name) { |n| "property_#{n}" }

    before :create do |property, params|
      casino_id = params.casino_id
      if casino_id
        property.casino = Casino.where(:id => casino_id).first || create(:casino, :id => casino_id)
      else
        puts "The casino_id should not be NULL"
      end
    end
  end
end