module SolidusSixSaferpay
  class Configuration
    include ActiveSupport::Configurable


    config_accessor(:payment_processing_success_handler)
  end
end
