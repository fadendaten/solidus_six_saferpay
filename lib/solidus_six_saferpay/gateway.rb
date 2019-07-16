module SolidusSixSaferpay

  # TODO: Find out if needed...
  class InvalidSaferpayPayment < StandardError
    def initialize(message: "Saferpay Payment is invalid", details: "")
      super("#{message}: #{details}".strip)
    end

    def full_message
      message
    end
  end

  class Gateway

    def initialize(options = {})
      # TODO: extract this to initializer
      SixSaferpay.configure do |config|
        config.customer_id = options.fetch(:customer_id, ENV.fetch('SIX_SAFERPAY_CUSTOMER_ID'))
        config.terminal_id = options.fetch(:terminal_id, ENV.fetch('SIX_SAFERPAY_TERMINAL_ID'))
        config.username = options.fetch(:username, ENV.fetch('SIX_SAFERPAY_USERNAME'))
        config.password = options.fetch(:password, ENV.fetch('SIX_SAFERPAY_PASSWORD'))
        config.success_url = options.fetch(:success_url, ENV.fetch('SIX_SAFERPAY_SUCCESS_URL'))
        config.fail_url = options.fetch(:fail_url, ENV.fetch('SIX_SAFERPAY_FAIL_URL'))
        config.base_url = options.fetch(:base_url, ENV.fetch('SIX_SAFERPAY_BASE_URL'))
        config.css_url = ''
      end
    end

    def initialize_checkout(order, payment_method)
      initialize_response = SixSaferpay::Client.post(
        interface_initialize_object(order, payment_method)
      )
      response(
        success: true,
        message: "Saferpay Initialize Checkout response: #{initialize_response}",
        api_response: initialize_response,
      )
    rescue SixSaferpay::Error => e
      handle_error(e, initialize_response)
    end

    def authorize
      raise NotImplementedError, "must be implemented in PaymentPageGateway or TransactionGateway"
    end

    def purchase(amount, payment_source, options = {})
      capture(amount, payment_source.transaction_id, options)
    end

    def capture(amount, transaction_id, options={})
      transaction_reference = SixSaferpay::TransactionReference.new(transaction_id: transaction_id)
      payment_capture = SixSaferpay::SixTransaction::Capture.new(transaction_reference: transaction_reference)

      capture_response = SixSaferpay::Client.post(payment_capture)

      response(
        success: true,
        message: "Saferpay Payment capture response: #{capture_response}",
        api_response: capture_response,
      )
    rescue SixSaferpay::Error => e
      handle_error(e, capture_response)
    end

    def credit(amount, transaction_id, options={})
      refund(amount, transaction_id, options)
    end

    def refund(amount, transaction_id, options = {})
      payment = Spree::Payment.find_by!(response_code: transaction_id)
      payment_amount = Spree::Money.new(payment.amount, currency: payment.currency)

      amount = SixSaferpay::Amount.new(value: payment_amount.cents, currency_code: payment.currency)
      refund = SixSaferpay::Refund.new(amount: amount, order_id: payment.order.number)
      capture_reference = SixSaferpay::CaptureReference.new(capture_id: payment.transaction_id)

      payment_refund = SixSaferpay::SixTransaction::Refund.new( refund: refund, capture_reference: capture_reference)

      refund_response = SixSaferpay::Client.post(payment_refund)

      response(
        success: true,
        message: "Saferpay Payment Refund respose: #{refund_response}",
        api_response: refund_response
      )
    rescue SixSaferpay::Error => e
      handle_error(e, refund_response)
    end

    def void(amount, transaction_id, options)
      transaction_reference = SixSaferpay::TransactionReference.new(transaction_id: transaction_id)
      payment_cancel = SixSaferpay::SixTransaction::Cancel.new(transaction_reference: transaction_reference)

      cancel_response = SixSaferpay::Client.post(payment_cancel)

      response(
        success: true,
        message: "Saferpay Payment Cancel response: #{cancel_response}",
        api_response: cancel_response
      )
    rescue SixSaferpay::Error => e
      handle_error(e, cancel_response)
    end

    def try_void(payment)
      if payment.checkout? && payment.transaction_id
        void(payment.amount, payment.transaction_id, originator: self)
      else
        raise "Can not void at the moment!"
      end
    end


    private

    def interface_initialize_params(order, payment_method)
      amount = Spree::Money.new(order.total, currency: order.currency)
      payment = SixSaferpay::Payment.new(
        amount: SixSaferpay::Amount.new(value: amount.cents, currency_code: amount.currency.iso_code),
        order_id: order.number,
        description: order.number
      )

      billing_address = order.billing_address
      billing_address = SixSaferpay::Address.new(
        first_name: billing_address.first_name,
        last_name: billing_address.last_name,
        date_of_birth: nil,
        company: nil,
        gender: nil,
        legal_form: nil,
        street: billing_address.address1,
        street_2: nil,
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
        street_2: nil,
        zip: shipping_address.zipcode,
        city: shipping_address.city,
        country_subdevision_code: nil,
        country_code: shipping_address.country.iso,
        phone: nil,
        email: nil,
      )
      payer = SixSaferpay::Payer.new(billing_address: billing_address, delivery_address: delivery_address)

      params = { payment: payment, payer: payer }

      six_payment_methods = payment_method.enabled_payment_methods
      params.merge!(payment_methods: six_payment_methods) unless six_payment_methods.blank?

      params
    end

    def response(success:, message:, api_response:, options: {})
      GatewayResponse.new(success, message, api_response, options)
    end

    def handle_error(error, response)
      # TODO: REMOVE THIS FOR PRODUCTION!!!!!
      if Rails.env.development?
        raise error, response
      end

      SolidusSixSaferpay::ErrorHandler.handle(error, level: :error)

      response(
        success: false,
        message: error.full_message,
        api_response: response
      )
    end
  end
end
