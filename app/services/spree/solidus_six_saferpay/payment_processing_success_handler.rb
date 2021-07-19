# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    # This handler can be overridden by host applications to manage control
    # flow after the payment authorization was successful and the payment was verified.
    # If not overridden, the handler will simply ensure that the order has
    # moved from the "payment" state to the next state.
    class PaymentProcessingSuccessHandler
      attr_reader :controller_context, :order

      def self.call(controller_context:, order:)
        new(controller_context: controller_context, order: order).call
      end

      def initialize(controller_context:, order:)
        @controller_context = controller_context
        @order = order
      end

      def call
        order.next! if order.payment?
      end
    end
  end
end
