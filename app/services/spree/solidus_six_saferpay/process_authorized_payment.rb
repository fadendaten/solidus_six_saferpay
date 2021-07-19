# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    class ProcessAuthorizedPayment
      attr_reader :saferpay_payment, :order, :success, :user_message

      def self.call(saferpay_payment)
        new(saferpay_payment).call
      end

      def initialize(saferpay_payment)
        @saferpay_payment = saferpay_payment
        @order = saferpay_payment.order
      end

      def call
        check_liability_shift_requirements!

        validate_payment!

        # SUCCESS!

        cancel_old_solidus_payments
        saferpay_payment.create_solidus_payment!
        @success = true

        self
      rescue ::SolidusSixSaferpay::InvalidSaferpayPayment => e
        cancel_saferpay_payment
        @user_message = e.full_message
        @success = false

        self
      end

      def success?
        @success
      end

      def gateway
        raise NotImplementedError, "Must be implemented in ProcessPaymentPagePayment or ProcessTransactionPayment"
      end

      private

      def validate_payment!
        PaymentValidator.call(saferpay_payment)
      end

      # Cancels only the saferpay payment without affecting solidus
      def cancel_saferpay_payment
        return unless transaction_id = saferpay_payment.transaction_id

        gateway.void(transaction_id)
      end

      # Cancels the solidus payments which automatically cancels the saferpay
      # payments
      def cancel_old_solidus_payments
        solidus_payments_to_cancel.each(&:cancel!)
      end

      def check_liability_shift_requirements!
        if require_liability_shift? && !liability_shifted? # rucocop:disable Style/GuardClause
          raise ::SolidusSixSaferpay::InvalidSaferpayPayment.new(details: I18n.t(:liability_shift_not_granted,
            scope: [:solidus_six_saferpay, :errors]))
        end
      end

      def require_liability_shift?
        saferpay_payment.payment_method.preferred_require_liability_shift
      end

      def liability_shifted?
        saferpay_payment.liability.liability_shift
      end

      def solidus_payments_to_cancel
        order.payments.valid.where.not(state: [:void])
      end
    end
  end
end
