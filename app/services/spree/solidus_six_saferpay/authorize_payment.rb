# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    class AuthorizePayment
      attr_reader :saferpay_payment, :order, :success

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
          saferpay_payment.update!(saferpay_payment_attributes(authorization.api_response))
          @success = true
        end
        self
      end

      def success?
        @success
      end

      def gateway
        raise NotImplementedError,
          "Must be implemented in AssertPaymentPage or AuthorizeTransaction" \
          "with UsePaymentPageGateway or UseTransactionGateway"
      end

      private

      def saferpay_payment_attributes(saferpay_response)
        payment_means = saferpay_response.payment_means
        card = payment_means.card

        attributes = {
          transaction_id: saferpay_response.transaction.id,
          transaction_status: saferpay_response.transaction.status,
          transaction_date: DateTime.parse(saferpay_response.transaction.date),
          six_transaction_reference: saferpay_response.transaction.six_transaction_reference,
          display_text: saferpay_response.payment_means.display_text,
          response_hash: saferpay_response.to_h
        }

        if card
          attributes[:masked_number] = card.masked_number
          attributes[:expiration_year] = card.exp_year
          attributes[:expiration_month] = card.exp_month
        end

        attributes
      end
    end
  end
end
