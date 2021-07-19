# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    class ProcessPaymentPagePayment < ProcessAuthorizedPayment
      include UsePaymentPageGateway
    end
  end
end
