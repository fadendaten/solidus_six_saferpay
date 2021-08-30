require 'rails_helper'

module SolidusSixSaferpay
  RSpec.describe TransactionGateway do
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

    let(:bill_address) { create(:address, name: 'John Billable') }
    let(:ship_address) { create(:address, name: 'John Shippable' ) }
    let(:order) { create(:order, total: 100, bill_address: bill_address, ship_address: ship_address) }
    let(:payment_method) { create(:saferpay_payment_method) }

    describe '#initialize_payment' do
      let(:api_initialize_response) do
        SixSaferpay::SixTransaction::InitializeResponse.new(
          response_header: SixSaferpay::ResponseHeader.new(request_id: 'request_id', spec_version: 'test'),
          token: 'TOKEN',
          expiration: '2015-01-30T12:45:22.258+01:00',
          redirect_required: true,
          redirect: SixSaferpay::Redirect.new(
            redirect_url: '/redirect/url',
            payment_means_required: true
          )
        )
      end

      let(:params) do
        {
          payment: instance_double(SixSaferpay::Payment),
          payer: instance_double(SixSaferpay::Payer),
          order: instance_double(SixSaferpay::Order),
          return_urls: instance_double(SixSaferpay::ReturnUrls)
        }
      end

      let(:payment_initialize_params) { instance_double(SolidusSixSaferpay::PaymentInitializeParams, params: params) }
      let(:payment_initialize_object) { instance_double(SixSaferpay::SixPaymentPage::Initialize) }

      it 'initializes a payment page payment' do
        allow(SixSaferpay::Client).to receive(:post).and_return(api_initialize_response)
        allow(SixSaferpay::SixTransaction::Initialize).to receive(:new).and_return(payment_initialize_object)
        allow(SolidusSixSaferpay::PaymentInitializeParams).to receive(:new).and_return(payment_initialize_params)

        gateway.initialize_payment(order, payment_method)

        expect(SolidusSixSaferpay::PaymentInitializeParams).to have_received(:new).with(
          order,
          payment_method,
          instance_of(SixSaferpay::ReturnUrls)
        )
        expect(SixSaferpay::SixTransaction::Initialize).to have_received(:new).with(params)
        expect(SixSaferpay::Client).to have_received(:post).with(payment_initialize_object)
      end

      context 'when the payment initialization is successful' do
        before do
          allow(SixSaferpay::Client).to receive(:post).and_return(api_initialize_response)
        end

        it 'returns a success gateway response' do
          allow(GatewayResponse).to receive(:new)

          gateway.initialize_payment(order, payment_method)

          expect(GatewayResponse).to have_received(:new).with(true, instance_of(String), api_initialize_response, {})
        end
      end

      context 'when the API raises an error' do
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

          gateway.initialize_payment(order, payment_method)

          expect(GatewayResponse).to have_received(:new)
        end
      end
    end

    describe '#inquire' do
      let(:payment) { create(:six_saferpay_payment, order: order, payment_method: payment_method) }

      let(:api_inquire_response) do
        SixSaferpay::SixTransaction::InquireResponse.new(
          response_header: SixSaferpay::ResponseHeader.new(request_id: 'test', spec_version: 'test'),
          transaction: SixSaferpay::Transaction.new(
            type: 'PAYMENT',
            status: 'AUTHORIZED',
            id: '723n4MAjMdhjSAhAKEUdA8jtl9jb',
            date: '2015-01-30T12:45:22.258+01:00',
            amount: SixSaferpay::Amount.new(value: '100', currency_code: 'USD'),
            six_transaction_reference: '0:0:3:723n4MAjMdhjSAhAKEUdA8jtl9jb',
          ),
          payment_means: SixSaferpay::ResponsePaymentMeans.new(
            brand: SixSaferpay::Brand.new(name: 'PaymentBrand'),
            display_text: 'xxxx xxxx xxxx 1234',
          )
        )
      end

      it 'performs an inquire request' do
        allow(SixSaferpay::SixTransaction::Inquire).to receive(:new).with(
          transaction_reference: payment.transaction_id
        ).and_call_original

        allow(SixSaferpay::Client).to receive(:post).and_return(api_inquire_response)

        gateway.inquire(payment)

        expect(SixSaferpay::Client).to have_received(:post).with(
          having_attributes(transaction_reference: payment.transaction_id)
        )
      end

      context 'when the payment inquiry is successful' do
        before do
          allow(SixSaferpay::Client).to receive(:post).with(
            instance_of(SixSaferpay::SixTransaction::Inquire)
          ).and_return(api_inquire_response)
        end

        it 'returns a successful gateway response' do
          allow(GatewayResponse).to receive(:new).with(true, instance_of(String), api_inquire_response, {})

          gateway.inquire(payment)

          expect(GatewayResponse).to have_received(:new)
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
            instance_of(SixSaferpay::SixTransaction::Inquire)
          ).and_raise(six_saferpay_error)
        end

        it 'handles the error gracefully' do
          allow(GatewayResponse).to receive(:new).with(
            false,
            six_saferpay_error.error_message,
            nil,
            error_name: six_saferpay_error.error_name
          )

          gateway.inquire(payment)

          expect(GatewayResponse).to have_received(:new)
        end
      end
    end

    describe '#authorize' do
      let(:payment) { create(:six_saferpay_payment, order: order, payment_method: payment_method) }

      let(:api_authorize_response) do
        SixSaferpay::SixTransaction::AuthorizeResponse.new(
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

      it 'performs an authorize request' do
        allow(SixSaferpay::Client).to receive(:post).and_return(api_authorize_response)

        gateway.authorize(payment.order.total, payment)

        expect(SixSaferpay::Client).to have_received(:post).with(
          having_attributes(
            token: payment.token,
            condition: nil,
            verification_code: nil,
            register_alias: nil,
          )
        )
      end

      context 'when the payment authorize is successful' do
        before do
          allow(SixSaferpay::Client).to receive(:post).with(
            instance_of(SixSaferpay::SixTransaction::Authorize)
          ).and_return(api_authorize_response)
        end

        it 'returns a successful gateway response' do
          allow(GatewayResponse).to receive(:new)

          gateway.authorize(payment.order.total, payment)

          expect(GatewayResponse).to have_received(:new).with(
            true,
            instance_of(String),
            api_authorize_response,
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
            instance_of(SixSaferpay::SixTransaction::Authorize)
          ).and_raise(six_saferpay_error)
        end

        it 'handles the error gracefully' do
          allow(GatewayResponse).to receive(:new).with(
            false,
            six_saferpay_error.error_message,
            nil,
            error_name: six_saferpay_error.error_name
          )

          gateway.authorize(payment.order.total, payment)

          expect(GatewayResponse).to have_received(:new)
        end
      end
    end
  end
end
