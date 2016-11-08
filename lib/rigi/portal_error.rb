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

  class InvalidLogin < PortalError
    def initialize(error_message)
      super(error_message)
    end
  end

  class InvalidUsername < PortalError; end
  class InvalidDomain < PortalError; end
  class RegisteredAccount <  PortalError; end
  class AccountNotInLdap <  PortalError; end
  class AccountNoCasino < PortalError; end

  class DomainCasinoNotFound < PortalError; end
  class CreateDomainLicenseeFail < PortalError; end
  class DeleteDomainLicenseeFail < PortalError; end

end
