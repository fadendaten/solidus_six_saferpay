module Spree
  module SolidusSixSaferpay
    class InitializePayment

      attr_reader :order, :payment_method, :redirect_url, :success

      def self.call(order, payment_method)
        new(order, payment_method).call
      end

      def initialize(order, payment_method)
        @order = order
        @payment_method = payment_method
        @success = false
      end

      def call
        gateway_response = gateway.initialize_payment(order, payment_method)

        if gateway_response.success?

          saferpay_payment = build_saferpay_payment(gateway_response.api_response)

          @redirect_url = saferpay_payment.redirect_url
          @success = saferpay_payment.save!
        end

        self
      end

      def success?
        @success
      end

      def gateway
        raise NotImplementedError, "Must be implemented in InitializePaymentPage or InitializeTransaction by including UsePaymentPageGateway or UseTransactionGateway"
      end

      private

      def build_saferpay_payment(api_response)
        Spree::SixSaferpayPayment.new(saferpay_payment_attributes(api_response))
      end

      def saferpay_payment_attributes(api_response)
        {
          order: order,
          payment_method: payment_method,
          token: api_response.token,
          expiration: DateTime.parse(api_response.expiration),
          response_hash: api_response.to_h
        }
      end
    end
  end
end
