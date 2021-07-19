# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    class CancelAuthorizedPayment
      attr_reader :saferpay_payment

      def self.call(saferpay_payment)
        new(saferpay_payment).call
      end

      def initialize(saferpay_payment)
        @saferpay_payment = saferpay_payment
      end

      def call
        if transaction_id = saferpay_payment.transaction_id
          gateway.void(saferpay_payment.transaction_id)
        else
          ::SolidusSixSaferpay::ErrorHandler.handle(
            ::SolidusSixSaferpay::InvalidSaferpayPayment.new(
              details: "Can not cancel payment #{saferpay_payment.id} because it has no transaction ID."
            )
          )
        end
      end

      private

      def gateway
        ::SolidusSixSaferpay::Gateway.new
      end
    end
  end
end
