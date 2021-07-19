# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    class ProcessTransactionPayment < ProcessAuthorizedPayment
      include UseTransactionGateway
    end
  end
end
