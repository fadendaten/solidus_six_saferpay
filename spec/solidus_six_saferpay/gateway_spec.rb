require 'rails_helper'

module SolidusSixSaferpay
  RSpec.describe Gateway do
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

    describe '#new' do
      let(:six_saferpay_config) { SixSaferpay.config }

      context 'when config is passed' do
        before do
          gateway
        end

        it 'configures the customer ID' do
          expect(six_saferpay_config.customer_id).to eq('CUSTOMER_ID')
        end

        it 'configures the terminal ID' do
          expect(six_saferpay_config.terminal_id).to eq('TERMINAL_ID')
        end

        it 'configures the username' do
          expect(six_saferpay_config.username).to eq('USERNAME')
        end

        it 'configures the password' do
          expect(six_saferpay_config.password).to eq('PASSWORD')
        end

        it 'configures the base URL' do
          expect(six_saferpay_config.base_url).to eq('https://test.saferpay-api-host.test')
        end

        it 'configures the CSS URL' do
          expect(six_saferpay_config.css_url).to eq('/custom/css/url')
        end
      end

      context 'when global options are not passed' do
        subject(:gateway) { described_class.new }

        before do
          allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_CUSTOMER_ID').and_return('ENV_CUSTOMER_ID')
          allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_TERMINAL_ID').and_return('ENV_TERMINAL_ID')
          allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_USERNAME').and_return('ENV_USERNAME')
          allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_PASSWORD').and_return('ENV_PASSWORD')
          allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_BASE_URL').and_return('ENV_BASE_URL')
          allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_CSS_URL').and_return('ENV_CSS_URL')

          gateway
        end

        it 'configures the customer ID from ENV' do
          expect(six_saferpay_config.customer_id).to eq('ENV_CUSTOMER_ID')
        end

        it 'configures the terminal ID from ENV' do
          expect(six_saferpay_config.terminal_id).to eq('ENV_TERMINAL_ID')
        end

        it 'configures the username from ENV' do
          expect(six_saferpay_config.username).to eq('ENV_USERNAME')
        end

        it 'configures the password from ENV' do
          expect(six_saferpay_config.password).to eq('ENV_PASSWORD')
        end

        it 'configures the base URL from ENV' do
          expect(six_saferpay_config.base_url).to eq('ENV_BASE_URL')
        end

        it 'configures the CSS URL from ENV' do
          expect(six_saferpay_config.css_url).to eq('ENV_CSS_URL')
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
        allow(gateway).to receive(:capture)

        gateway.purchase(amount, payment)

        expect(gateway).to have_received(:capture).with(amount, payment.transaction_id, {})
      end
    end

    describe '#capture' do
      let(:amount) { 500 }

      let(:api_capture_response) do
        SixSaferpay::SixTransaction::CaptureResponse.new(
          response_header: SixSaferpay::ResponseHeader.new(request_id: 'request_id', spec_version: 'test'),
          capture_id: 'CAPTURE_ID',
          status: 'CAPTURED',
          date: '2015-01-30T12:45:22.258+01:00'
        )
      end

      it 'captures the given transaction via the Saferpay API' do
        allow(SixSaferpay::Client).to receive(:post).and_return(api_capture_response)

        # amount is disregarded but kept to match the default gateway interface for #capture
        gateway.capture(0, 'TRANSACTION_ID')

        expect(SixSaferpay::Client).to have_received(:post).with(
          having_attributes(
            transaction_reference: having_attributes(
              transaction_id: 'TRANSACTION_ID'
            )
          )
        )
      end

      context 'when the capture is successful' do
        before do
          allow(SixSaferpay::Client).to receive(:post).with(
            instance_of(SixSaferpay::SixTransaction::Capture)
          ).and_return(api_capture_response)
        end

        it 'returns a success gateway response' do
          allow(GatewayResponse).to receive(:new)

          gateway.capture(0, 'TRANSACTION_ID')

          expect(GatewayResponse).to have_received(:new).with(
            true,
            instance_of(String),
            api_capture_response,
            { authorization: api_capture_response.capture_id }
          )
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
          allow(SixSaferpay::Client).to receive(:post).with(
            instance_of(SixSaferpay::SixTransaction::Capture)
          ).and_raise(six_saferpay_error)
        end

        it 'handles the error gracefully' do
          allow(GatewayResponse).to receive(:new)

          gateway.capture(amount, 'TRANSACTION_ID')

          expect(GatewayResponse).to have_received(:new).with(
            false,
            six_saferpay_error.error_message,
            nil,
            error_name: six_saferpay_error.error_name
          )
        end
      end
    end

    describe '#void' do
      let(:transaction_id) { 'TRANSACTION_ID' }

      let(:api_cancel_response) do
        SixSaferpay::SixTransaction::CancelResponse.new(
          response_header: SixSaferpay::ResponseHeader.new(request_id: 'request_id', spec_version: 'test'),
          transaction_id: 'TRANSACTION_ID',
        )
      end

      it 'cancels the payment' do
        allow(SixSaferpay::Client).to receive(:post).and_return(api_cancel_response)

        gateway.void('TRANSACTION_ID')

        expect(SixSaferpay::Client).to have_received(:post).with(
          having_attributes(
            transaction_reference: having_attributes(
              transaction_id: 'TRANSACTION_ID'
            )
          )
        )
      end

      context 'when the cancellation is successful' do
        before do
          allow(SixSaferpay::Client).to receive(:post).with(
            instance_of(SixSaferpay::SixTransaction::Cancel)
          ).and_return(api_cancel_response)
        end

        it 'returns a success gateway response' do
          allow(GatewayResponse).to receive(:new)

          gateway.void(transaction_id)

          expect(GatewayResponse).to have_received(:new).with(
            true,
            instance_of(String),
            api_cancel_response,
            {}
          )
        end
      end

      context 'when the API raises an error' do
        let(:six_saferpay_error) do
          SixSaferpay::Error.new(
            response_header: SixSaferpay::ResponseHeader.new(
              request_id: 'request_id',
              spec_version: 'test'
            ),
            behavior: 'ABORT',
            error_name: 'INVALID_TRANSACTION',
            error_message: 'error_message'
          )
        end

        before do
          allow(SixSaferpay::Client).to receive(:post).with(
            instance_of(SixSaferpay::SixTransaction::Cancel)
          ).and_raise(six_saferpay_error)
        end

        it 'handles the error gracefully' do
          allow(GatewayResponse).to receive(:new)

          gateway.void(transaction_id)

          expect(GatewayResponse).to have_received(:new).with(
            false,
            six_saferpay_error.error_message,
            nil,
            error_name: six_saferpay_error.error_name
          )
        end
      end
    end

    describe '#try_void' do
      let(:transaction_id) { "TRANSACTION_ID" }
      let(:payment) { create(:payment, response_code: transaction_id) }

      context 'when payment is in checkout state and has transaction_id' do
        it 'voids the payment' do
          allow(gateway).to receive(:void)

          gateway.try_void(payment)

          expect(gateway).to have_received(:void).with(transaction_id, originator: gateway)
        end
      end

      context 'when payment is not in checkout state' do
        let(:payment) { create(:payment, state: :failed, response_code: transaction_id) }

        it 'does not void the payment' do
          allow(gateway).to receive(:void)

          gateway.try_void(payment)

          expect(gateway).not_to have_received(:void)
        end
      end

      context 'when the payment has no transaction_id' do
        let(:payment) { create(:payment, response_code: nil) }

        it 'does not void the payment' do
          allow(gateway).to receive(:void)

          gateway.try_void(payment)

          expect(gateway).not_to have_received(:void)
        end
      end
    end

    describe '#credit' do
      it 'is aliased to #refund' do
        allow(gateway).to receive(:refund)

        gateway.credit(200, 'TRANSACTION_ID', { a: 'a' })

        expect(gateway).to have_received(:refund).with(200, 'TRANSACTION_ID', { a: 'a' })
      end
    end

    describe '#refund' do
      let!(:payment) { create(:payment_using_saferpay, response_code: 'TRANSACTION_ID', amount: 400) }

      let(:api_refund_response) do
        transaction = SixSaferpay::Transaction.new(
          type: 'REFUND',
          status: 'AUTHORIZED',
          id: 'REFUND_ID',
          date: '2015-01-30T12:45:22.258+01:00',
          amount: SixSaferpay::Amount.new(
            value: 300,
            currency_code: payment.order.currency
          ),
          six_transaction_reference: 'SIX_TRANSACTION_REFERENCE'
        )

        payment_means = SixSaferpay::ResponsePaymentMeans.new(
          brand: SixSaferpay::Brand.new(name: 'PaymentBrand'),
          display_text: 'xxxx xxxx xxxx 1234'
        )

        SixSaferpay::SixTransaction::RefundResponse.new(
          response_header: SixSaferpay::ResponseHeader.new(request_id: 'request_id', spec_version: 'test'),
          transaction: transaction,
          payment_means: payment_means
        )
      end

      it 'refunds the payment' do
        allow(SixSaferpay::Client).to receive(:post).with(
          instance_of(SixSaferpay::SixTransaction::Refund)
        ).and_return(api_refund_response)

        allow(gateway).to receive(:capture)

        gateway.refund(100, 'TRANSACTION_ID')

        expect(SixSaferpay::Client).to have_received(:post).with(
          having_attributes(
            refund: having_attributes(
              order_id: payment.order.number,
              amount: having_attributes(
                value: 100,
                currency_code: payment.currency,
              )
            ),
            capture_reference: having_attributes(
              capture_id: 'TRANSACTION_ID'
            )
          )
        )
      end

      it 'captures the refund directly after' do
        allow(SixSaferpay::Client).to receive(:post).with(
          instance_of(SixSaferpay::SixTransaction::Refund)
        ).and_return(api_refund_response)

        allow(gateway).to receive(:capture)

        gateway.refund(100, 'TRANSACTION_ID')

        expect(gateway).to have_received(:capture).with(100, 'REFUND_ID', {})
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
          allow(SixSaferpay::Client).to receive(:post).with(
            instance_of(SixSaferpay::SixTransaction::Refund)
          ).and_return(api_refund_response)

          allow(SixSaferpay::Client).to receive(:post).with(
            instance_of(SixSaferpay::SixTransaction::Capture)
          ).and_return(api_capture_response)
        end

        it 'returns a success gateway response' do
          allow(GatewayResponse).to receive(:new)

          gateway.refund(100, 'TRANSACTION_ID')

          expect(GatewayResponse).to have_received(:new).with(
            true,
            instance_of(String),
            api_capture_response,
            { authorization: 'CAPTURE_ID' }
          )
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

        context 'when refunding the payment' do
          before do
            allow(SixSaferpay::Client).to receive(:post).with(
              instance_of(SixSaferpay::SixTransaction::Refund)
            ).and_raise(six_saferpay_error)
          end

          it 'handles the error gracefully' do
            allow(GatewayResponse).to receive(:new)

            gateway.refund(100, 'TRANSACTION_ID')

            expect(GatewayResponse).to have_received(:new).with(
              false,
              six_saferpay_error.error_message,
              nil,
              error_name: six_saferpay_error.error_name
            )
          end
        end

        context 'when capturing the payment' do
          before do
            allow(SixSaferpay::Client).to receive(:post).with(
              instance_of(SixSaferpay::SixTransaction::Refund)
            ).and_return(api_refund_response)

            allow(SixSaferpay::Client).to receive(:post).with(
              instance_of(SixSaferpay::SixTransaction::Capture)
            ).and_raise(six_saferpay_error)
          end

          it 'handles the error gracefully' do
            allow(GatewayResponse).to receive(:new)

            gateway.refund(100, 'TRANSACTION_ID')

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
end
