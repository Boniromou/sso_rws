module AdminPortal
  class AdminPortalError < StandardError
    def initialize(msg='system error')
      @error_code = 500
      @error_level = 'warning'
      @error_message = msg
    end
  end

  class InvalidTime < AdminPortalError
    def initialize
      super(I18n.t("flash_message.time_invalid"))
    end
  end

  class NotAllowPropagation < AdminPortalError
    def initialize
      super(I18n.t("flash_message.not_allow_propagation"))
    end
  end
end
