module Spree
  module SolidusSixSaferpay

    # This handler can be overridden by host applications to manage control
    # flow if no order can be found when SIX Saferpay performs the callback
    # request after the user submits a payment.
    # If not overridden, the handler will simply trigger an error.
    class OrderNotFoundHandler

      attr_reader :controller_context, :order_number

      def self.call(controller_context:, order_number:)
        new(controller_context: controller_context, order_number: order_number).call
      end

      def initialize(controller_context:, order_number:)
        @controller_context = controller_context
        @order_number = order_number
      end

      def call
        ::SolidusSixSaferpay::ErrorHandler.handle(
          StandardError.new("No solidus order could be found for number #{order_number}")
        )
      end
    end
  end
end
