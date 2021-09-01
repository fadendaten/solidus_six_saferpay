# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    class PaymentValidator
      attr_reader :order, :saferpay_payment

      def self.call(saferpay_payment)
        new(saferpay_payment).call
      end

      def initialize(saferpay_payment)
        @order = saferpay_payment.order
        @saferpay_payment = saferpay_payment
      end

      def call
        saferpay_transaction = saferpay_payment.transaction

        validate_payment_authorized(saferpay_transaction)
        validate_order_reference(saferpay_transaction)
        validate_order_amount(saferpay_transaction)
      end

      def validate_payment_authorized(saferpay_transaction)
        if saferpay_transaction.status != "AUTHORIZED"
          error("Status should be 'AUTHORIZED', is: '#{saferpay_transaction.status}'")
        end

        true
      end

      def validate_order_reference(saferpay_transaction)
        if order.number != saferpay_transaction.order_id
          error("Order ID should be '#{order.number}', is: '#{saferpay_transaction.order_id}'")
        end

        true
      end

      def validate_order_amount(saferpay_transaction)
        order_amount = Spree::Money.new(order.total, currency: order.currency)

        saferpay_transaction_currency = saferpay_transaction.amount.currency_code
        if order_amount.currency.iso_code != saferpay_transaction_currency
          error("Currency should be '#{order.currency}', is: '#{saferpay_transaction_currency}'")
        end

        saferpay_transaction_cents = saferpay_transaction.amount.value
        if order_amount.cents.to_s != saferpay_transaction_cents
          error("Order total (cents) should be '#{order_amount.cents}', is: '#{saferpay_transaction_cents}'")
        end

        true
      end

      private

      def error(details)
        raise ::SolidusSixSaferpay::InvalidSaferpayPayment.new(details: details)
      end
    end
  end
end
