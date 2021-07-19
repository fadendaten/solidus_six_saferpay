# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    module PaymentPage
      # explicit parent must be stated, otherwise Spree::CheckoutController has precendence
      class CheckoutController < SolidusSixSaferpay::CheckoutController
        private

        def initialize_payment(order, payment_method)
          InitializePaymentPage.call(order, payment_method)
        end

        def authorize_payment(saferpay_payment)
          AssertPaymentPage.call(saferpay_payment)
        end

        def process_authorization(saferpay_payment)
          ProcessPaymentPagePayment.call(saferpay_payment)
        end

        def inquire_payment(saferpay_payment)
          InquirePaymentPagePayment.call(saferpay_payment)
        end
      end
    end
  end
end
