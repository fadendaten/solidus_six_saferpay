# frozen_string_literal: true

module SolidusSixSaferpay
  class Gateway
    include Spree::RouteAccess

    def initialize(options = {})
      SixSaferpay.configure do |config|
        # Allow config via ENV for static values
        config.customer_id = options.fetch(:customer_id) { ENV.fetch('SIX_SAFERPAY_CUSTOMER_ID') }
        config.terminal_id = options.fetch(:terminal_id) { ENV.fetch('SIX_SAFERPAY_TERMINAL_ID') }
        config.username = options.fetch(:username) { ENV.fetch('SIX_SAFERPAY_USERNAME') }
        config.password = options.fetch(:password) { ENV.fetch('SIX_SAFERPAY_PASSWORD') }
        config.base_url = options.fetch(:base_url) { ENV.fetch('SIX_SAFERPAY_BASE_URL') }
        config.css_url = options.fetch(:css_url) { ENV.fetch('SIX_SAFERPAY_CSS_URL') }
      end
    end

    def initialize_payment(order, payment_method)
      initialize_response = SixSaferpay::Client.post(
        interface_initialize_object(order, payment_method)
      )
      response(
        true,
        "Saferpay Initialize Checkout response: #{initialize_response.to_h}",
        initialize_response,
      )
    rescue SixSaferpay::Error => e
      handle_error(e, initialize_response)
    end

    def authorize(_amount, _saferpay_payment, _options = {})
      raise NotImplementedError, "must be implemented in PaymentPageGateway or TransactionGateway"
    end

    def inquire(_saferpay_payment, _options = {})
      raise NotImplementedError, "must be implemented in PaymentPageGateway or TransactionGateway"
    end

    def purchase(amount, saferpay_payment, options = {})
      capture(amount, saferpay_payment.transaction_id, options)
    end

    def capture(_amount, transaction_id, _options = {})
      transaction_reference = SixSaferpay::TransactionReference.new(transaction_id: transaction_id)
      payment_capture = SixSaferpay::SixTransaction::Capture.new(transaction_reference: transaction_reference)

      capture_response = SixSaferpay::Client.post(payment_capture)

      response(
        true,
        "Saferpay Payment Capture response: #{capture_response.to_h}",
        capture_response,
        { authorization: capture_response.capture_id }
      )
    rescue SixSaferpay::Error => e
      handle_error(e, capture_response)
    end

    def void(transaction_id, _options = {})
      transaction_reference = SixSaferpay::TransactionReference.new(transaction_id: transaction_id)
      payment_cancel = SixSaferpay::SixTransaction::Cancel.new(transaction_reference: transaction_reference)

      cancel_response = SixSaferpay::Client.post(payment_cancel)

      response(
        true,
        "Saferpay Payment Cancel response: #{cancel_response.to_h}",
        cancel_response
      )
    rescue SixSaferpay::Error => e
      handle_error(e, cancel_response)
    end

    def try_void(payment)
      if payment.checkout? && payment.transaction_id
        void(payment.transaction_id, originator: self)
      end
    end

    # aliased to #refund for compatibility with solidus internals
    def credit(amount_cents, transaction_id, options = {})
      refund(amount_cents, transaction_id, options)
    end

    def refund(amount_cents, transaction_id, options = {})
      payment = Spree::Payment.find_by!(response_code: transaction_id)

      saferpay_amount = SixSaferpay::Amount.new(value: amount_cents, currency_code: payment.currency)
      saferpay_refund = SixSaferpay::Refund.new(amount: saferpay_amount, order_id: payment.order.number)
      capture_reference = SixSaferpay::CaptureReference.new(capture_id: payment.transaction_id)

      payment_refund = SixSaferpay::SixTransaction::Refund.new(refund: saferpay_refund,
        capture_reference: capture_reference)

      if refund_response = SixSaferpay::Client.post(payment_refund)

        # actually capture the refund
        capture(amount_cents, refund_response.transaction.id, options)
      end
    rescue SixSaferpay::Error => e
      handle_error(e, refund_response)
    end

    private

    def interface_initialize_object(_order, _payment_method)
      raise NotImplementedError, "Must be implemented in PaymentPageGateway or TransactionGateway"
    end

    def interface_initialize_params(order, payment_method)
      amount = Spree::Money.new(order.total, currency: order.currency)
      payment = SixSaferpay::Payment.new(
        amount: SixSaferpay::Amount.new(value: amount.cents, currency_code: amount.currency.iso_code),
        order_id: order.number,
        description: order.number
      )

      billing_address = order.billing_address
      bill_address = SixSaferpay::Address.new(
        first_name: billing_address.first_name,
        last_name: billing_address.last_name,
        date_of_birth: nil,
        company: nil,
        gender: nil,
        legal_form: nil,
        street: billing_address.address1,
        street2: billing_address.address2,
        zip: billing_address.zipcode,
        city: billing_address.city,
        country_subdevision_code: nil,
        country_code: billing_address.country.iso,
        phone: nil,
        email: nil,
      )
      shipping_address = order.shipping_address
      delivery_address = SixSaferpay::Address.new(
        first_name: shipping_address.first_name,
        last_name: shipping_address.last_name,
        date_of_birth: nil,
        company: nil,
        gender: nil,
        legal_form: nil,
        street: shipping_address.address1,
        street2: shipping_address.address2,
        zip: shipping_address.zipcode,
        city: shipping_address.city,
        country_subdevision_code: nil,
        country_code: shipping_address.country.iso,
        phone: nil,
        email: nil,
      )
      payer = SixSaferpay::Payer.new(
        language_code: I18n.locale,
        billing_address: bill_address,
        delivery_address: delivery_address
      )

      params = { payment: payment, payer: payer, return_urls: return_urls(order) }

      six_payment_methods = payment_method.enabled_payment_methods
      params[:payment_methods] = six_payment_methods if six_payment_methods.present?

      params
    end

    def return_urls(_order)
      raise NotImplementedError, "Must be implemented in PaymentPageGateway or TransactionGateway"
    end

    def response(success, message, api_response, options = {})
      GatewayResponse.new(success, message, api_response, options)
    end

    def handle_error(error, response)
      # Call host error handler hook
      SolidusSixSaferpay::ErrorHandler.handle(error, level: :error)

      response(
        false,
        error.error_message,
        response,
        error_name: error.error_name
      )
    end
  end
end
