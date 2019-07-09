require 'activemerchant'
require 'six_saferpay'

module ActiveMerchant
  module Billing
    module Gateways
      class SixSaferpayGateway < Gateway
        class InvalidSaferpayPayment < StandardError
          def initialize(message: "Saferpay Payment is invalid", details: "")
            super("#{message}: #{details}".strip)
          end

          def full_message
            message
          end
        end

        # undef .supports? so that it is delegated to the payment method
        # see https://github.com/solidusio/solidus/blob/master/core/app/models/spree/payment_method/credit_card.rb#L20
        class << self
          undef_method :supports?
        end

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
            message: "Saferpay Transaction authorize response: #{initialize_response}",
            params: initialize_response.to_h
          )
        rescue SixSaferpay::Error => e
          handle_error(e, initialize_response)
        end

        def purchase(amount, payment_source, options = {})
          auth_response = authorize(amount, payment_source, options)
          if auth_response.success?
            capture(amount, payment_source.transaction_id, options)
          else
            auth_response
          end
        end


        def capture(amount, transaction_id, options={})
          transaction_reference = SixSaferpay::TransactionReference.new(transaction_id: transaction_id)
          payment_page_capture = SixSaferpay::SixTransaction::Capture.new(transaction_reference: transaction_reference)

          capture_response = SixSaferpay::Client.post(payment_page_capture)

          response(
            success: true,
            message: "Saferpay Payment Page capture response: #{capture_response}",
            params: capture_response.to_h,
            options: { authorization: capture_response.capture_id }
          )
        rescue SixSaferpay::Error => e
          handle_error(e, capture_response)
        end

        private

        def ensure_valid_payment(payment_source, saferpay_response)
          order = payment_source.order
          ensure_authorized(saferpay_response)
          ensure_correct_order(order, saferpay_response)
          ensure_equal_amount(order, saferpay_response)

          true
        end

        def ensure_authorized(saferpay_response)
          if saferpay_response.transaction.status != "AUTHORIZED"
            raise InvalidSaferpayPayment.new(details: "Status should be 'AUTHORIZED', is: '#{saferpay_response.transaction.status}'")
          end
        end

        def ensure_correct_order(order, saferpay_response)
          if order.number != saferpay_response.transaction.order_id
            raise InvalidSaferpayPayment.new(details: "Order ID should be '#{order.number}', is: '#{saferpay_response.transaction.order_id}'")
          end

          true
        end

        def ensure_equal_amount(order, saferpay_response)
          order_amount = Spree::Money.new(order.total, currency: order.currency)
          saferpay_transaction = saferpay_response.transaction

          if order_amount.currency.iso_code != saferpay_transaction.amount.currency_code
            raise InvalidSaferpayPayment.new(details: "Currency should be '#{order.currency}', is: '#{saferpay_transaction.amount.currency_code}'")
          end
          if order_amount.cents.to_s != saferpay_transaction.amount.value.to_s
            raise InvalidSaferpayPayment.new(details: "Order total (cents) should be '#{order_amount.cents}', is: '#{saferpay_transaction.amount.value}'")
          end

          true
        end

        def update_payment_source!(payment_source, saferpay_response)
          attributes = {}
          attributes[:transaction_id] = saferpay_response.transaction.id
          attributes[:transaction_status] = saferpay_response.transaction.status
          attributes[:transaction_date] = DateTime.parse(saferpay_response.transaction.date)
          attributes[:six_transaction_reference] = saferpay_response.transaction.six_transaction_reference
          attributes[:display_text] = saferpay_response.payment_means.display_text

          if card = saferpay_response.payment_means.card
            attributes
            attributes[:masked_number] = card.masked_number,
            attributes[:expiration_year] = card.exp_year,
            attributes[:expiration_month] = card.exp_month
          end
          payment_source.update_attributes!(attributes)
        end

        def handle_error(error, response)
          SolidusSixSaferpay::ErrorHandler.handle(error, level: :error)

          response(
            success: false,
            message: error.full_message,
            params: response.to_h
          )
        end

        def response(success:, message:, params: {}, options: {})
          ActiveMerchant::Billing::Response.new(success, message, params, options)
        end

        private

        def interface_initialize_object(order, payment_method)
          raise "Must be implemented in SixSaferpayPaymentPageGateway or SixSaferpayTransactionGateway"
        end

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
      end
    end
  end
end
