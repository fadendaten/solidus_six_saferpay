module SolidusSixSaferpay
  class Configuration
    include ActiveSupport::Configurable


    config_accessor(:payment_processing_order_not_found_handler)
    config_accessor(:payment_processing_payment_not_found_handler)
    config_accessor(:payment_processing_success_handler)
    config_accessor(:error_handlers) { [] }
  end
end
