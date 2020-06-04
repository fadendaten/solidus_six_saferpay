module SolidusSixSaferpay
  class Configuration
    include ActiveSupport::Configurable

    config_accessor(:error_handlers) { [] }
  end
end
