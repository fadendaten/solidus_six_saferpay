# frozen_string_literal: true

module SolidusSixSaferpay
  class Configuration
    attr_accessor :error_handlers, :address_name_extractor_class, :allow_unsafe_address_name_extraction,
      :payment_initialize_params_class, :line_item_type_deductor_class

    def initialize
      @error_handlers = []
      @address_name_extractor_class = ::SolidusSixSaferpay::AddressNameExtractor
      @allow_unsafe_address_name_extraction = true
      @payment_initialize_params_class = ::SolidusSixSaferpay::PaymentInitializeParams
      @line_item_type_deductor_class = ::SolidusSixSaferpay::LineItemTypeDeductor
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    alias config configuration

    def configure
      yield configuration
    end
  end
end
