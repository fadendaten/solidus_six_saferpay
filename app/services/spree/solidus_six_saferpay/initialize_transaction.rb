# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    class InitializeTransaction < InitializePayment
      include UseTransactionGateway

      private

      def saferpay_payment_attributes(initialize_response)
        super.merge(
          redirect_url: initialize_response.redirect.redirect_url
        )
      end
    end
  end
end
