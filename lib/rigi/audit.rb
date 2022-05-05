module Rigi
  module Audit
    module Configuration
      extend self

      def load(file_path=nil)
        file_to_load = file_path || Rails.root.join('config', 'audit.yml')
        symbolized_h = Rigi::Format.symbolize_keys(YAML.load_file(file_to_load))
        Rigi.const_set('AUDIT_CONFIG', symbolized_h[:audit_target])
      end
    end
  end
end
