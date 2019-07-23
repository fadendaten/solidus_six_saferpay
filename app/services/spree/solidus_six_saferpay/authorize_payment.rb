module Spree
  module SolidusSixSaferpay
    # TODO: SPEC
    class AuthorizePayment
      attr_reader :saferpay_payment, :order, :success, :user_message

      def self.call(saferpay_payment)
        new(saferpay_payment).call
      end

      def initialize(saferpay_payment)
        @saferpay_payment = saferpay_payment
        @order = saferpay_payment.order
      end

      def call
        authorization = gateway.authorize(order.total, saferpay_payment)

        if authorization.success?
          saferpay_payment.update_attributes!(saferpay_payment_attributes(authorization.api_response))
          @success = true
        end
        self
      end

      def success?
        @success
      end

      private

      def gateway
        raise NotImplementedError, "Must be implemented in AssertPaymentPage or AuthorizeTransaction with UsePaymentPageGateway or UseTransactionGateway"
      end

      def saferpay_payment_attributes(saferpay_response)
        payment_means = saferpay_response.payment_means
        brand = payment_means.brand
        card = payment_means.card

        attributes = {}
        attributes[:transaction_id] = saferpay_response.transaction.id
        attributes[:transaction_status] = saferpay_response.transaction.status
        attributes[:transaction_date] = DateTime.parse(saferpay_response.transaction.date)
        attributes[:six_transaction_reference] = saferpay_response.transaction.six_transaction_reference
        attributes[:display_text] = saferpay_response.payment_means.display_text

        if card
          attributes[:masked_number] = card.masked_number
          attributes[:expiration_year] = card.exp_year
          attributes[:expiration_month] = card.exp_month
        end

        attributes[:response_hash] = saferpay_response.to_h
        attributes
      end
    end
  end
end