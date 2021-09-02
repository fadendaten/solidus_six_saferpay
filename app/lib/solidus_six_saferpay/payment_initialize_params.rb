# frozen_string_literal: true

module SolidusSixSaferpay
  # Provide values for initializing saferpay payment
  # This class can be overridden to override all or specific values by setting
  # config.payment_initialize_params_class
  #
  #
  class PaymentInitializeParams
    include Spree::Tax::TaxHelpers

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

    private

    def six_payment
      six_amount = Spree::Money.new(order.total, currency: order.currency)
      SixSaferpay::Payment.new(
        amount: SixSaferpay::Amount.new(value: six_amount.cents, currency_code: six_amount.currency.iso_code),
        order_id: order.number,
        description: order.number
      )
    end

    def six_address(order, solidus_address)
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
        phone: solidus_address.phone,
        email: order.email,
      )
    end

    def six_payer
      SixSaferpay::Payer.new(
        language_code: I18n.locale,
        billing_address: six_address(order, order.bill_address),
        delivery_address: six_address(order, order.ship_address)
      )
    end

    def six_order
      six_items = order.line_items.map do |line_item|
        variant = line_item.variant

        SixSaferpay::Item.new(
          type: item_type(line_item),
          id: variant.product_id,
          variant_id: variant.id,
          name: variant.sku,
          quantity: line_item.quantity,
          unit_price: Spree::Money.new(line_item.price, currency: order.currency).cents,
          tax_rate: tax_rate(line_item),
          tax_amount: Spree::Money.new(line_item.included_tax_total, currency: order.currency).cents
        )
      end

      SixSaferpay::Order.new(
        items: six_items
      )
    end

    def extract_name(address)
      SolidusSixSaferpay.config.address_name_extractor_class.new(address)
    end

    def item_type(line_item)
      SolidusSixSaferpay.config.line_item_type_deductor_class.new(line_item).type
    end

    def tax_rate(line_item)
      # from TaxHelpers module
      tax_rates = rates_for_item(line_item)

      if tax_rates.empty?
        Rails.logger.warn "Error: No tax rate detected, can not determine tax rate " \
          "of line item [#{line_item.order.number} #{line_item.id}]"
        return 0
      end

      if tax_rates.length > 1
        Rails.logger.warn "Error: Multiple tax rates detected, choosing first tax rate " \
          "of line item [#{line_item.order.number} #{item.id}"
      end

      tax_rate = tax_rates.first
      (tax_rate.amount * 10_000).to_i
    end
  end
end
