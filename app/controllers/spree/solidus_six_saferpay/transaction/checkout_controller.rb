module Spree
  module SolidusSixSaferpay
    module Transaction
    # explicit parent must be stated, otherwise Spree::CheckoutController has precendence
      class CheckoutController < SolidusSixSaferpay::CheckoutController

        private

        def initialize_payment(order, payment_method)
          InitializeTransaction.call(order, payment_method)
        end

        def authorize_payment(saferpay_payment)
          AuthorizeTransaction.call(saferpay_payment)
        end

        def process_authorization(saferpay_payment)
          ProcessTransactionPayment.call(saferpay_payment)
        end

        def inquire_payment(saferpay_payment)
          InquireTransactionPayment.call(saferpay_payment)
        end
      end
    end
  end
end
