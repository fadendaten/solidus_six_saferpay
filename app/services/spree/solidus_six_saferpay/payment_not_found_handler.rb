# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    # This handler can be overridden by host applications to manage control
    # flow if no payment can be found when SIX Saferpay performs the callback
    # request after the user submits a payment.
    # If not overridden, the handler will simply trigger an error.
    class PaymentNotFoundHandler
      attr_reader :controller_context, :order

      def self.call(controller_context:, order:)
        new(controller_context: controller_context, order: order).call
      end

      def initialize(controller_context:, order:)
        @controller_context = controller_context
        @order = order
      end

      def call
        ::SolidusSixSaferpay::ErrorHandler.handle(
          StandardError.new("No Saferpay Payment found for order #{order.number}")
        )
      end
    end
  end
end
