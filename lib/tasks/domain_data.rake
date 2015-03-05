#$:.unshift(Rails.root + '/vendor/gems/lax-support-0.6.31/lib')
require 'lax-support'

namespace :domain_data do
   task :migrate do
        LaxSupport::DomainDataMigration.new.handle_migrate
   end


   task :rollback do
        LaxSupport::DomainDataMigration.new.handle_rollback
   end
end
