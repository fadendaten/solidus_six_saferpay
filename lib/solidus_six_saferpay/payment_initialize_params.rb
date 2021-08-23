# frozen_string_literal: true

module SolidusSixSaferpay
  class PaymentInitializeParams
    attr_reader :order, :payment_method, :return_urls

    def initialize(order, payment_method, return_urls)
      @order = order
      @payment_method = payment_method
      @return_urls = return_urls
    end

    def params
      initialize_params = {
        payment: six_payment,
        order: six_order,
        payer: six_payer,
        return_urls: return_urls
      }

      six_payment_methods = payment_method.enabled_payment_methods
      initialize_params[:payment_methods] = six_payment_methods if six_payment_methods.present?

      initialize_params
    end

    def six_payment
      six_amount = Spree::Money.new(order.total, currency: order.currency)
      SixSaferpay::Payment.new(
        amount: SixSaferpay::Amount.new(value: six_amount.cents, currency_code: six_amount.currency.iso_code),
        order_id: order.number,
        description: order.number
      )
    end

    def six_address(solidus_address)
      address_name = extract_name(solidus_address)
      SixSaferpay::Address.new(
        first_name: address_name.first_name,
        last_name: address_name.last_name,
        date_of_birth: nil,
        company: nil,
        gender: nil,
        legal_form: nil,
        street: solidus_address.address1,
        street2: solidus_address.address2,
        zip: solidus_address.zipcode,
        city: solidus_address.city,
        country_subdevision_code: nil,
        country_code: solidus_address.country.iso,
        phone: nil,
        email: nil,
      )
    end

    def six_payer
      SixSaferpay::Payer.new(
        language_code: I18n.locale,
        billing_address: six_address(order.bill_address),
        delivery_address: six_address(order.ship_address)
      )
    end

    def six_order
      six_items = order.line_items.map do |item|
        variant = item.variant

        SixSaferpay::Item.new(
          type: 'PHYSICAL',
          id: item.id,
          variant_id: variant.id,
          name: variant.sku,
          quantity: item.quantity,
          unit_price: item.total.to_i
        )
      end

      SixSaferpay::Order.new(
        items: six_items
      )
    end

    def extract_name(address)
      SolidusSixSaferpay.config.address_name_extractor_class.new(address)
    end
  end
end
