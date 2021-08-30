# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    class InquireTransactionPayment < InquirePayment
      include UseTransactionGateway
    end
  end
end
