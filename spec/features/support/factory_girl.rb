require 'factory_girl'

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end

FactoryGirl.definition_file_paths = ["#{::Rails.root}/spec/features/factories"]
FactoryGirl.find_definitions