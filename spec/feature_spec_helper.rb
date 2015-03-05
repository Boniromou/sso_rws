ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment",__FILE__)
require 'rspec/rails'
require 'capybara/rails'

Devise::TestHelpers
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
Dir[Rails.root.join("spec/features/support/**/*.rb")].each {|f| require f}

Capybara.ignore_hidden_elements = false

RSpec.configure do |config|
  config.include Devise::TestHelpers, :type => :controller
  config.extend ControllerHelpers, :type => :controller
  config.fixture_path = "#{::Rails.root}/spec/features/fixtures"
  config.use_transactional_fixtures = true

  config.before(:each) do
    allow_any_instance_of(ApplicationController).to receive(:client_ip).and_return("192.1.1.1")
  end

  config.infer_spec_type_from_file_location!
end
