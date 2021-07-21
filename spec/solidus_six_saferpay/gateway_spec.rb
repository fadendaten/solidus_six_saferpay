require 'rails_helper'

module SolidusSixSaferpay
  RSpec.describe Gateway do
    # config options
    let(:customer_id) { 'CUSTOMER_ID' }
    let(:terminal_id) { 'TERMINAL_ID' }
    let(:username) { 'USERNAME' }
    let(:password) { 'PASSWORD' }
    let(:base_url) { 'https://test.saferpay-api-host.test' }
    let(:css_url) { '/custom/css/url' }

    let(:gateway) do
      described_class.new(
        customer_id: customer_id,
        terminal_id: terminal_id,
        username: username,
        password: password,
        base_url: base_url,
        css_url: css_url
      )
    end

    describe '#new' do
      it 'configures the API client' do
        gateway = described_class.new(
          customer_id: customer_id,
          terminal_id: terminal_id,
          username: username,
          password: password,
          base_url: base_url,
          css_url: css_url
        )

        config = SixSaferpay.config

        expect(config.customer_id).to eq(customer_id)
        expect(config.terminal_id).to eq(terminal_id)
        expect(config.username).to eq(username)
        expect(config.password).to eq(password)
        expect(config.base_url).to eq(base_url)
        expect(config.css_url).to eq(css_url)
      end

      context 'when global options are not passed' do
        before do
          allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_CUSTOMER_ID').and_return(customer_id)
          allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_TERMINAL_ID').and_return(terminal_id)
          allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_USERNAME').and_return(username)
          allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_PASSWORD').and_return(password)
          allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_BASE_URL').and_return(base_url)
          allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_CSS_URL').and_return(css_url)
        end

        it 'falls back to ENV vars', :aggregate_failures do
          gateway = described_class.new

          config = SixSaferpay.config

          expect(config.customer_id).to eq(customer_id)
          expect(config.terminal_id).to eq(terminal_id)
          expect(config.username).to eq(username)
          expect(config.password).to eq(password)
          expect(config.base_url).to eq(base_url)
          expect(config.css_url).to eq(css_url)
        end
      end
    end

    describe '#initialize_payment' do
      let(:order) { create(:order) }
      let(:payment_method) { create(:saferpay_payment_method) }

      it 'fails because it does not know which interface to use' do
        expect { gateway.initialize_payment(order, payment_method) }.to raise_error(NotImplementedError)
      end
    end

    describe '#authorize' do
      let(:payment) { create(:six_saferpay_payment) }
      let(:amount) { payment.order.total }

      it 'fails because authorize must be defined in a subclass' do
        expect { gateway.authorize(amount, payment) }.to raise_error(NotImplementedError)
      end
    end

    describe '#inquire' do
      let(:payment) { create(:six_saferpay_payment) }

      it 'fails because inquire must be defined in a subclass' do
        expect { gateway.inquire(payment) }.to raise_error(NotImplementedError)
      end
    end

    describe '#purchase' do
      let(:payment) { create(:six_saferpay_payment) }
      let(:amount) { payment.order.total }

      it 'delegates to capture (with a different signature)' do
        expect(gateway).to receive(:capture).with(amount, payment.transaction_id, {})

        gateway.purchase(amount, payment)
      end
    end

    describe '#capture' do
      let(:amount) { 500 }
      let(:transaction_id) { "TRANSACTION_ID" }

      let(:api_capture_response) do
        SixSaferpay::SixTransaction::CaptureResponse.new(
          response_header: SixSaferpay::ResponseHeader.new(request_id: 'request_id', spec_version: 'test'),
          capture_id: 'CAPTURE_ID',
          status: 'CAPTURED',
          date: '2015-01-30T12:45:22.258+01:00'
        )
      end

      let(:transaction_reference) {
        instance_double("SixSaferpay::TransactionReference", transaction_id: transaction_id)
      }
      let(:saferpay_capture) { instance_double("SixSaferpay::SixTransaction::Capture") }

      it 'captures the given transaction via the Saferpay API' do
        expect(SixSaferpay::TransactionReference).to receive(:new).with(transaction_id: transaction_id).and_return(transaction_reference)
        expect(SixSaferpay::SixTransaction::Capture).to receive(:new).with(transaction_reference: transaction_reference).and_return(saferpay_capture)
        expect(SixSaferpay::Client).to receive(:post).with(saferpay_capture).and_return(api_capture_response)

        gateway.capture(amount, transaction_id)
      end

      context 'when the capture is successful' do
        before do
          allow(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Capture)).and_return(api_capture_response)
        end

        it 'returns a success gateway response' do
          expect(GatewayResponse).to receive(:new).with(true, instance_of(String), api_capture_response,
            { authorization: api_capture_response.capture_id } )

          gateway.capture(amount, transaction_id)
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
          allow(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Capture)).and_raise(six_saferpay_error)
        end

        it 'handles the error gracefully' do
          expect(GatewayResponse).to receive(:new).with(false, six_saferpay_error.error_message, nil,
            error_name: six_saferpay_error.error_name)

          gateway.capture(amount, transaction_id)
        end
      end
    end

    describe '#void' do
      let(:transaction_id) { 'TRANSACTION_ID' }

      let(:transaction_reference) { instance_double("SixSaferpay::TransactionReference") }
      let(:saferpay_cancel) { instance_double("SixSaferpay::SixTransaction::Cancel") }

      let(:api_cancel_response) do
        SixSaferpay::SixTransaction::CancelResponse.new(
          response_header: SixSaferpay::ResponseHeader.new(request_id: 'request_id', spec_version: 'test'),
          transaction_id: transaction_id,
        )
      end

      it 'cancels the payment' do
        expect(SixSaferpay::TransactionReference).to receive(:new).with(transaction_id: transaction_id).and_return(transaction_reference)
        expect(SixSaferpay::SixTransaction::Cancel).to receive(:new).with(transaction_reference: transaction_reference).and_return(saferpay_cancel)
        expect(SixSaferpay::Client).to receive(:post).with(saferpay_cancel).and_return(api_cancel_response)

        gateway.void(transaction_id)
      end

      context 'when the cancellation is successful' do
        before do
          allow(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Cancel)).and_return(api_cancel_response)
        end

        it 'returns a success gateway response' do
          expect(GatewayResponse).to receive(:new).with(true, instance_of(String), api_cancel_response, {})

          gateway.void(transaction_id)
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
          allow(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Cancel)).and_raise(six_saferpay_error)
        end

        it 'handles the error gracefully' do
          expect(GatewayResponse).to receive(:new).with(false, six_saferpay_error.error_message, nil,
            error_name: six_saferpay_error.error_name)

          gateway.void(transaction_id)
        end
      end
    end

    describe '#try_void' do
      let(:transaction_id) { "TRANSACTION_ID" }
      let(:payment) { create(:payment, response_code: transaction_id) }

      context 'if payment is in checkout state and has transaction_id' do
        it 'voids the payment' do
          expect(gateway).to receive(:void).with(transaction_id, originator: gateway)

          gateway.try_void(payment)
        end
      end
    end

    describe '#credit' do
      let(:amount) { 400 }
      let(:transaction_id) { 'TRANSACTION_ID' }
      let(:options) { { a: 'a', b: 'b' } }

      it 'is aliased to #refund' do
        expect(gateway).to receive(:refund).with(amount, transaction_id, options)

        gateway.credit(amount, transaction_id, options)
      end
    end

    describe '#refund' do
      let(:transaction_amount) { 400 }
      let(:refund_amount) { 300 }
      let(:transaction_id) { 'TRANSACTION_ID' }
      let(:refund_id) { 'REFUND_ID' }

      let!(:payment) { create(:payment_using_saferpay, response_code: transaction_id, amount: transaction_amount) }

      let(:saferpay_refund) do
        amount = SixSaferpay::Amount.new(value: (refund_amount * 100), currency_code: payment.order.currency)
        refund = SixSaferpay::Refund.new(amount: amount, order_id: payment.order.number)
        capture_reference = SixSaferpay::CaptureReference.new(capture_id: transaction_id)

        SixSaferpay::SixTransaction::Refund.new(
          refund: refund,
          capture_reference: capture_reference
        )
      end

      let(:api_refund_response) do
        transaction = SixSaferpay::Transaction.new(
          type: 'REFUND',
          status: 'AUTHORIZED',
          id: refund_id,
          date: '2015-01-30T12:45:22.258+01:00',
          amount: SixSaferpay::Amount.new(
            value: refund_amount,
            currency_code: payment.order.currency
          ),
          six_transaction_reference: 'SIX_TRANSACTION_REFERENCE'
        )

        payment_means = SixSaferpay::ResponsePaymentMeans.new(
          brand: SixSaferpay::Brand.new(name: 'BrandName'),
          display_text: 'xxxxxxxxxxxx1234'
        )

        SixSaferpay::SixTransaction::RefundResponse.new(
          response_header: SixSaferpay::ResponseHeader.new(request_id: 'request_id', spec_version: 'test'),
          transaction: transaction,
          payment_means: payment_means
        )
      end

      it 'refunds and directly captures the payment' do
        expect(SixSaferpay::SixTransaction::Refund).to receive(:new).with(refund: instance_of(SixSaferpay::Refund),
          capture_reference: instance_of(SixSaferpay::CaptureReference)).and_return(saferpay_refund)

        expect(SixSaferpay::Client).to receive(:post).with(saferpay_refund).and_return(api_refund_response)

        expect(gateway).to receive(:capture).with(refund_amount, refund_id, {})

        gateway.refund(refund_amount, transaction_id)
      end

      context 'when the refund is successful' do
        let(:api_capture_response) do
          SixSaferpay::SixTransaction::CaptureResponse.new(
            response_header: SixSaferpay::ResponseHeader.new(request_id: 'request_id', spec_version: 'test'),
            capture_id: 'CAPTURE_ID',
            status: 'CAPTURED',
            date: '2015-01-30T12:45:22.258+01:00'
          )
        end

        before do
          allow(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Refund)).and_return(api_refund_response)
          allow(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Capture)).and_return(api_capture_response)
        end

        it 'returns a success gateway response' do
          expect(GatewayResponse).to receive(:new).with(true, instance_of(String), api_capture_response,
            { authorization: 'CAPTURE_ID' })

          gateway.refund(refund_amount, transaction_id)
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

        context 'during refunding' do
          before do
            allow(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Refund)).and_raise(six_saferpay_error)
          end

          it 'handles the error gracefully' do
            expect(GatewayResponse).to receive(:new).with(false, six_saferpay_error.error_message, nil,
              error_name: six_saferpay_error.error_name)

            gateway.refund(refund_amount, transaction_id)
          end
        end

        context 'during capture' do
          before do
            allow(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Refund)).and_return(api_refund_response)
            allow(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Capture)).and_raise(six_saferpay_error)
          end

          it 'handles the error gracefully' do
            expect(GatewayResponse).to receive(:new).with(false, six_saferpay_error.error_message, nil,
              error_name: six_saferpay_error.error_name)

            gateway.refund(refund_amount, transaction_id)
          end
        end
      end
    end
  end
end
