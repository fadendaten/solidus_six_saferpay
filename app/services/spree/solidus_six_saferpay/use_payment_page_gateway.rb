# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    module UsePaymentPageGateway
      include RouteAccess

      def gateway
        ::SolidusSixSaferpay::PaymentPageGateway.new
      end
    end
  end
end
