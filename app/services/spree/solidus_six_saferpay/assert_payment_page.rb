# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    class AssertPaymentPage < AuthorizePayment
      include UsePaymentPageGateway
    end
  end
end
