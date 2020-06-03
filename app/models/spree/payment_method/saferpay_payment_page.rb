module Spree
  class PaymentMethod::SaferpayPaymentPage < PaymentMethod::SaferpayPaymentMethod


    def gateway_class
      ::SolidusSixSaferpay::PaymentPageGateway
    end

    def init_path(order)
      url_helpers.solidus_six_saferpay_payment_page_init_path(order.number)
    end
  end
end
