module Spree
  class PaymentMethod::SaferpayTransaction < PaymentMethod::SaferpayPaymentMethod

    def gateway_class
      ::SolidusSixSaferpay::TransactionGateway
    end

    def init_path(order)
      url_helpers.solidus_six_saferpay_transaction_init_path(order.number)
    end
  end
end
