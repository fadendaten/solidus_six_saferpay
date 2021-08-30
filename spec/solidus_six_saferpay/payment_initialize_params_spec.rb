require 'rails_helper'

module SolidusSixSaferpay
  RSpec.describe PaymentInitializeParams do
    subject(:service) do
      described_class.new(
        order,
        payment_method,
        return_urls,
      )
    end

    let(:variant1) { create(:variant) }
    let(:variant2) { create(:variant, product: variant1.product) }
    let(:order) do
      create(
        :order_with_line_items,
        line_items_attributes: [
          { variant_id: variant1.id, quantity: 1, price: 10 },
          { variant_id: variant2.id, quantity: 2, price: 20 }
        ],
        total: 50,
        bill_address: create(:address, name: 'John Billable'),
        ship_address: create(:address, name: 'John Shippable'),
      )
    end
    let(:payment_method) { create(:saferpay_payment_method) }
    let(:return_urls) { SixSaferpay::ReturnUrls.new(success: 'success', fd_fail: 'fail', fd_abort: 'abort') }

    describe '#params' do
      it 'returns params required to initialize a six saferpay payment' do
        expect(service.params).to match({
          payment: having_attributes(
            amount: having_attributes(
              value: order.total * 100,
              currency_code: order.currency
            )
          ),
          order: having_attributes(
            items: match_array([
              having_attributes(
                type: 'PHYSICAL',
                id: variant1.product_id,
                variant_id: variant1.id,
                name: variant1.sku,
                quantity: 1,
                unit_price: 1000,
                tax_rate: 0,
                tax_amount: 0
              ),
              having_attributes(
                type: 'PHYSICAL',
                id: variant2.product_id,
                variant_id: variant2.id,
                name: variant2.sku,
                quantity: 2,
                unit_price: 2000,
                tax_rate: 0,
                tax_amount: 0
              )
            ])
          ),
          payer: having_attributes(
            language_code: I18n.locale,
            billing_address: having_attributes(
              first_name: 'John',
              last_name: 'Billable',
              date_of_birth: nil,
              company: nil,
              gender: nil,
              legal_form: nil,
              street: order.billing_address.address1,
              street2: order.billing_address.address2,
              zip: order.billing_address.zipcode,
              city: order.billing_address.city,
              country_subdevision_code: nil,
              country_code: order.billing_address.country.iso,
              phone: nil,
              email: nil
            ),
            delivery_address: having_attributes(
              first_name: 'John',
              last_name: 'Shippable',
              date_of_birth: nil,
              company: nil,
              gender: nil,
              legal_form: nil,
              street: order.shipping_address.address1,
              street2: order.shipping_address.address2,
              zip: order.shipping_address.zipcode,
              city: order.shipping_address.city,
              country_subdevision_code: nil,
              country_code: order.shipping_address.country.iso,
              phone: nil,
              email: nil
            )
          ),
          return_urls: having_attributes(
            success: 'success',
            fd_fail: 'fail',
            fd_abort: 'abort'
          )
        })
      end
    end
  end
end
