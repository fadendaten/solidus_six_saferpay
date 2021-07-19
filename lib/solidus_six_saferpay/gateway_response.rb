# frozen_string_literal: true

module SolidusSixSaferpay
  class GatewayResponse
    attr_reader :api_response, :message, :test, :error_name, :authorization

    def initialize(success, message, api_response, options = {})
      @success, @message, @api_response = success, message, api_response
      @error_name = options[:error_name]
      @authorization = options[:authorization]
    end

    def success?
      @success
    end

    def to_s
      message
    end

    # To ensure that solidus sets the response_code after successful capture,
    # we need to pass it as an "authorization", however if we do this then
    # solidus also expects there to be an "avs_result"
    #
    # see https://github.com/solidusio/solidus/blob/master/core/app/models/spree/payment/processing.rb#L171
    def avs_result
      {}
    end

    # To ensure that solidus sets the response_code after successful capture,
    # we need to pass it as an "authorization", however if we do this then
    # solidus also expects this response to respond to :cvv_result
    #
    # see https://github.com/solidusio/solidus/blob/master/core/app/models/spree/payment/processing.rb#L171
    def cvv_result
      nil
    end
  end
end
