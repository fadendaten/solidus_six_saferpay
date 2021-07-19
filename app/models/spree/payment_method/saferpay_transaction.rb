# frozen_string_literal: true

module Spree
  class PaymentMethod::SaferpayTransaction < PaymentMethod::SaferpayPaymentMethod # rubocop:disable Style/ClassAndModuleChildren
    def gateway_class
      ::SolidusSixSaferpay::TransactionGateway
    end

    def init_path(order)
      url_helpers.solidus_six_saferpay_transaction_init_path(order.number)
    end
  end
end
