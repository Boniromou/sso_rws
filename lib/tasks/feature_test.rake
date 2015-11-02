namespace :test do
  if Rails.env.development?
    desc "Run all feature tests"
    RSpec::Core::RakeTask.new(:feature) do |t|
      t.rspec_opts = ["-cfd"]
      t.pattern = ['spec/features/*.rb']
    end
  end
end
