module Rigi
  module LdapConfiguration
    extend self

    def load(file_path=nil)
      file_to_load = file_path || Rails.root.join('config', 'ldap.yml')
      symbolized_h = symbolize_keys(YAML.load_file(file_to_load)[Rails.env])
      SsoRws::Application.config.ldap_config = symbolized_h
    end

    def symbolize_keys(hash)
      hash.inject({}){|result, (key, value)|
        new_key = case key
                  when String then key.to_sym
                  else key
                  end
        new_value = case value
                    when Hash then symbolize_keys(value)
                    else value
                    end
        result[new_key] = new_value
        result
      }
    end
  end
end

Rigi::LdapConfiguration.load