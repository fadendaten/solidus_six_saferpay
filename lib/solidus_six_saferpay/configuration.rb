# frozen_string_literal: true

module SolidusSixSaferpay
  class Configuration
    # Define here the settings for this extension, e.g.:
    #
    attr_accessor :error_handlers
    attr_accessor :address_name_extractor_class
    attr_accessor :allow_unsafe_address_name_extraction

    def initialize
      @error_handlers = []
      @address_name_extractor_class = ::SolidusSixSaferpay::AddressNameExtractor
      @allow_unsafe_address_name_extraction = true
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
