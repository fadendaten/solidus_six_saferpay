# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    module UseTransactionGateway
      include RouteAccess

      def gateway
        ::SolidusSixSaferpay::TransactionGateway.new
      end
    end
  end
end
