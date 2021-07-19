# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    class InitializePaymentPage < InitializePayment
      include UsePaymentPageGateway

      private

      def saferpay_payment_attributes(api_response)
        super.merge(
          redirect_url: api_response.redirect_url
        )
      end
    end
  end
end
