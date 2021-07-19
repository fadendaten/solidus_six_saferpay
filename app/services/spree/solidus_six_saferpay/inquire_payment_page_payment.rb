# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    class InquirePaymentPagePayment < InquirePayment
      include UsePaymentPageGateway
    end
  end
end
