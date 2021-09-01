require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe InitializePaymentPage do
      subject(:initialize_payment_page) { described_class.new(order, payment_method) }

      let(:order) { create(:order) }
      let(:payment_method) { create(:saferpay_payment_method) }

      describe '#gateway' do
        it_behaves_like "it uses the payment page gateway"
      end

      describe '#call' do
        # https://saferpay.github.io/jsonapi/#Payment_v1_PaymentPage_Initialize
        let(:api_response) do
          SixSaferpay::SixPaymentPage::InitializeResponse.new(
            response_header: SixSaferpay::ResponseHeader.new(request_id: 'test', spec_version: 'test'),
            token: '234uhfh78234hlasdfh8234e1234',
            expiration: '2015-01-30T12:45:22.258+01:00',
            redirect_url: '/saferpay/redirect/url'
          )
        end

        let(:gateway_response) do
          ::SolidusSixSaferpay::GatewayResponse.new(
            gateway_success,
            "initialize success: #{gateway_success}",
            api_response
          )
        end

        before do
          allow(initialize_payment_page).to receive(:gateway).and_return(
            instance_double('SolidusSixSaferpay::Gateway', initialize_payment: gateway_response)
          )
        end

        context 'when not successful' do
          let(:gateway_success) { false }

          it 'indicates failure' do
            initialize_payment_page.call

            expect(initialize_payment_page).not_to be_success
          end

          it 'does not create a saferpay payment' do
            expect { initialize_payment_page.call }.not_to(change { Spree::SixSaferpayPayment.count })
          end
        end

        context 'when successful' do
          let(:gateway_success) { true }

          it 'creates a new saferpay payment' do
            expect { initialize_payment_page.call }.to change { Spree::SixSaferpayPayment.count }.from(0).to(1)
          end

          it 'sets the redirect_url' do
            initialize_payment_page.call

            expect(initialize_payment_page.redirect_url).to eq('/saferpay/redirect/url')
          end

          it 'indicates success' do
            initialize_payment_page.call

            expect(initialize_payment_page).to be_success
          end
        end
      end
    end
  end
end
