namespace :test do
  desc "Run all feature tests"
  RSpec::Core::RakeTask.new(:feature) do |t|
    t.rspec_opts = ["-cfd"]
    t.pattern = ['spec/features/*.rb']
  end
end
