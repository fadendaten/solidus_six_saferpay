module Spree
  class PaymentMethod::SixSaferpayPaymentMethod < PaymentMethod::CreditCard

    AVAILABLE_PAYMENT_METHODS = %w(ALIPAY AMEX BANCONTACT BONUS DINERS DIRECTDEBIT EPRZELEWY EPS GIROPAY IDEAL INVOICE JCB MAESTRO MASTERCARD MYONE PAYPAL PAYDIREKT POSTCARD POSTFINANCE SAFERPAYTEST SOFORT TWINT UNIONPAY VISA VPAY)

    delegate :try_void, to: :gateway

    preference :as_iframe, :boolean, default: false

    # Configure all available Payment Methods for the Saferpay API as
    # preferences
    AVAILABLE_PAYMENT_METHODS.each do |six_payment_method|
      preference "payment_method_#{six_payment_method.downcase}", :boolean, default: false
    end

    def enabled_payment_methods
      AVAILABLE_PAYMENT_METHODS.select do |six_payment_method|
        public_send("preferred_payment_method_#{six_payment_method.downcase}")
      end
    end

    def payment_source_class
      Spree::SixSaferpayPayment
    end

    def profiles_supported?
      false
    end

    # We want to automatically capture the payment when the order is completed
    def auto_capture
      true
    end
  end
end
