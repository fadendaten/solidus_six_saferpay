# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    class AuthorizeTransaction < AuthorizePayment
      include UseTransactionGateway
    end
  end
end
