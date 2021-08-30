require 'rails_helper'

module SolidusSixSaferpay
  RSpec.describe PaymentPageGateway do
    subject(:gateway) do
      described_class.new(
        customer_id: 'CUSTOMER_ID',
        terminal_id: 'TERMINAL_ID',
        username: 'USERNAME',
        password: 'PASSWORD',
        base_url: 'https://test.saferpay-api-host.test',
        css_url: '/custom/css/url'
      )
    end

    let(:order) { create(:order) }
    let(:payment_method) { create(:saferpay_payment_method) }

    describe '#initialize_payment' do
      let(:api_initialize_response) do
        SixSaferpay::SixPaymentPage::InitializeResponse.new(
          response_header: SixSaferpay::ResponseHeader.new(request_id: 'request_id', spec_version: 'test'),
          token: 'TOKEN',
          expiration: '2015-01-30T12:45:22.258+01:00',
          redirect_url: '/redirect/url'
        )
      end

      let(:payment_initialize_params) do
        instance_double(SolidusSixSaferpay::PaymentInitializeParams, params: {
          payment: instance_double(SixSaferpay::Payment),
          payer: instance_double(SixSaferpay::Payer),
          order: instance_double(SixSaferpay::Order),
          return_urls: instance_double(SixSaferpay::ReturnUrls)
        })
      end
      let(:payment_initialize_object) { instance_double(SixSaferpay::SixPaymentPage::Initialize) }

      it 'initializes a payment page payment' do
        allow(SixSaferpay::Client).to receive(:post).and_return(api_initialize_response)
        allow(SixSaferpay::SixPaymentPage::Initialize).to receive(:new).and_return(payment_initialize_object)
        allow(SolidusSixSaferpay::PaymentInitializeParams).to receive(:new).and_return(payment_initialize_params)

        gateway.initialize_payment(order, payment_method)

        expect(SixSaferpay::Client).to have_received(:post).with(payment_initialize_object)
      end

      context 'when the payment initialization is successful' do
        it 'returns a success gateway response' do
          allow(SixSaferpay::Client).to receive(:post).with(
            instance_of(SixSaferpay::SixPaymentPage::Initialize)
          ).and_return(api_initialize_response)

          allow(GatewayResponse).to receive(:new)

          gateway.initialize_payment(order, payment_method)

          expect(GatewayResponse).to have_received(:new).with(true, instance_of(String), api_initialize_response, {})
        end
      end

      context 'when the API raises an error' do
        before do
          allow(SixSaferpay::Client).to receive(:post).and_raise(
            SixSaferpay::Error.new(
              response_header: SixSaferpay::ResponseHeader.new(request_id: 'request_id', spec_version: 'test'),
              behavior: 'ABORT',
              error_name: 'INVALID_TRANSACTION',
              error_message: 'error_message'
            )
          )
        end

        it 'handles the error gracefully' do
          allow(GatewayResponse).to receive(:new)

          gateway.initialize_payment(order, payment_method)

          expect(GatewayResponse).to have_received(:new).with(
            false,
            'error_message',
            nil,
            error_name: 'INVALID_TRANSACTION'
          )
        end
      end
    end

    describe '#inquire' do
      let(:payment) { create(:six_saferpay_payment, order: order, payment_method: payment_method) }

      let(:api_inquire_response) do
        SixSaferpay::SixPaymentPage::AssertResponse.new(
          response_header: SixSaferpay::ResponseHeader.new(request_id: 'test', spec_version: 'test'),
          transaction: SixSaferpay::Transaction.new(
            type: 'PAYMENT',
            status: 'AUTHORIZED',
            id: '723n4MAjMdhjSAhAKEUdA8jtl9jb',
            date: '2015-01-30T12:45:22.258+01:00',
            amount: SixSaferpay::Amount.new(value: (order.total * 100), currency_code: order.currency),
            six_transaction_reference: '0:0:3:723n4MAjMdhjSAhAKEUdA8jtl9jb'
          ),
          payment_means: SixSaferpay::ResponsePaymentMeans.new(
            brand: SixSaferpay::Brand.new(name: 'PaymentBrand'),
            display_text: 'xxxx xxxx xxxx 1234'
          )
        )
      end

      it 'performs an assert request' do
        allow(SixSaferpay::Client).to receive(:post).and_return(api_inquire_response)

        gateway.inquire(payment)

        expect(SixSaferpay::Client).to have_received(:post).with(
          having_attributes(
            token: payment.token
          )
        )
      end

      context 'when the payment inquiry is successful' do
        before do
          allow(SixSaferpay::Client).to receive(:post).with(
            instance_of(SixSaferpay::SixPaymentPage::Assert)
          ).and_return(api_inquire_response)
        end

        it 'returns a successful gateway response' do
          allow(GatewayResponse).to receive(:new)

          gateway.inquire(payment)

          expect(GatewayResponse).to have_received(:new).with(
            true,
            instance_of(String),
            api_inquire_response,
            {}
          )
        end
      end

      context 'when the API returns an error' do
        let(:six_saferpay_error) do
          SixSaferpay::Error.new(
            response_header: SixSaferpay::ResponseHeader.new(request_id: 'request_id', spec_version: 'test'),
            behavior: 'ABORT',
            error_name: 'INVALID_TRANSACTION',
            error_message: 'error_message'
          )
        end

        before do
          allow(SixSaferpay::Client).to receive(:post).with(
            instance_of(SixSaferpay::SixPaymentPage::Assert)
          ).and_raise(six_saferpay_error)
        end

        it 'handles the error gracefully' do
          allow(GatewayResponse).to receive(:new)

          gateway.inquire(payment)

          expect(GatewayResponse).to have_received(:new).with(
            false,
            six_saferpay_error.error_message,
            nil,
            error_name: six_saferpay_error.error_name
          )
        end
      end
    end

    describe '#authorize' do
      let(:payment) { create(:six_saferpay_payment, order: order, payment_method: payment_method) }

      it 'calls assert' do
        allow(gateway).to receive(:assert)

        gateway.authorize(100, payment)

        expect(gateway).to have_received(:assert).with(payment, {})
      end
    end

    describe '#assert' do
      let(:payment) { create(:six_saferpay_payment, order: order, payment_method: payment_method) }

      let(:api_assert_response) do
        SixSaferpay::SixPaymentPage::AssertResponse.new(
          response_header: SixSaferpay::ResponseHeader.new(request_id: 'test', spec_version: 'test'),
          transaction: SixSaferpay::Transaction.new(
            type: 'PAYMENT',
            status: 'AUTHORIZED',
            id: '723n4MAjMdhjSAhAKEUdA8jtl9jb',
            date: '2015-01-30T12:45:22.258+01:00',
            amount: SixSaferpay::Amount.new(value: (order.total * 100), currency_code: order.currency),
            six_transaction_reference: '0:0:3:723n4MAjMdhjSAhAKEUdA8jtl9jb'
          ),
          payment_means: SixSaferpay::ResponsePaymentMeans.new(
            brand: SixSaferpay::Brand.new(name: 'PaymentBrand'),
            display_text: 'xxxx xxxx xxxx 1234'
          )
        )
      end

      it 'performs an assert request' do
        allow(SixSaferpay::Client).to receive(:post).and_return(api_assert_response)

        gateway.assert(payment)

        expect(SixSaferpay::Client).to have_received(:post).with(
          having_attributes(
            token: payment.token,
          )
        )
      end

      context 'when the payment assert is successful' do
        before do
          allow(SixSaferpay::Client).to receive(:post).with(
            instance_of(SixSaferpay::SixPaymentPage::Assert)
          ).and_return(api_assert_response)
        end

        it 'returns a successful gateway response' do
          allow(GatewayResponse).to receive(:new)

          gateway.assert(payment)

          expect(GatewayResponse).to have_received(:new).with(
            true,
            instance_of(String),
            api_assert_response,
            {}
          )
        end
      end

      context 'when the API returns an error' do
        let(:six_saferpay_error) do
          SixSaferpay::Error.new(
            response_header: SixSaferpay::ResponseHeader.new(request_id: 'request_id', spec_version: 'test'),
            behavior: 'ABORT',
            error_name: 'INVALID_TRANSACTION',
            error_message: 'error_message'
          )
        end

        before do
          allow(SixSaferpay::Client).to receive(:post).and_raise(six_saferpay_error)
        end

        it 'handles the error gracefully' do
          allow(GatewayResponse).to receive(:new)

          gateway.assert(payment)

          expect(GatewayResponse).to have_received(:new).with(
            false,
            six_saferpay_error.error_message,
            nil,
            error_name: six_saferpay_error.error_name
          )
        end
      end
    end
  end
end
