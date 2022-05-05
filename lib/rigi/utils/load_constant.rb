module Rigi
  module Setting
    extend self

    def define_constant
      app_config = YAML.load_file(config_file)[Rails.env].symbolize_keys

      default_config.merge(app_config).each do |k, v|
        Object.const_set(k.to_s.upcase, v)
      end
    end

    def config_file
      "#{Rails.root}/config/constant.yml"
    end

    def default_config
      {}
    end
  end
end
