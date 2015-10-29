module Rigi
  class PortalError < StandardError
    attr_reader :error_code, :error_level, :error_message, :data

    def initialize(msg='system error', data={})
      # @record = record  # or as_json
      @error_code = 500
      @error_level = 'warning'
      @error_message = msg
      @data = data
    end

    private
    # helper to generate error message to corresponding locale key
    # compose_msg_key("invalid_status_update", "resume", "test_player_propagation")
    # => "invalid_status_update.resume_test_player_propagation"
    def format_error_locale(key_category, action_name, target_name)
      "#{key_category}.#{action_name}_#{target_name}"
    end
  end

  class InvalidTime < PortalError
    def initialize
      super
    end
  end

  class NotAllowPropagation < PortalError
    def initialize
      super
    end
  end

  class TestPlayerNotFound < PortalError
    def initialize
      super
    end
  end

  class DuplicatedTestPlayer < PortalError
    def initialize(test_player_info)
      super('', test_player_info)
    end
  end

  class InvalidTestPlayerData < PortalError
    def initialize
      super
    end
  end

  class InvalidStatusUpdate < PortalError
    def initialize #(record, attempted_action)
      #locale_key = format_error_locale("invalid_status_update", record.class.name.underscore, attempted_action)
      super
    end
  end

  class InvalidArgument < PortalError
    def initialize(msg)
      super(msg)
    end
  end

  class DenomLevelNotFound < PortalError
    def initialize
      super
    end
  end

  class NotUnderMaintenance < PortalError
    def initialize(game_info)
      super('', game_info)
    end
  end

  class CurrentVersionProtect < PortalError
    def initialize
      super
    end
  end
end
