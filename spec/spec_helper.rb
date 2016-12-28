ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment",__FILE__)
require 'rspec/rails'
require 'database_cleaner'

RSpec.configure do |config|
  config.before(:each) do
    allow_any_instance_of(ApplicationController).to receive(:client_ip).and_return("192.1.1.1")
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :truncation
  end

  config.infer_spec_type_from_file_location!

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.after(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end
end
