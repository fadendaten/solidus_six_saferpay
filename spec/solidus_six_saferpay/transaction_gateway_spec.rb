require 'rails_helper'

module SolidusSixSaferpay
  RSpec.describe TransactionGateway do
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

    let(:order) { create(:order, total: 100) }
    let(:payment_method) { create(:saferpay_payment_method) }

    let(:payment) { create(:six_saferpay_payment, order: order, payment_method: payment_method) }

    before do
      allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_CUSTOMER_ID').and_return(customer_id)
      allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_TERMINAL_ID').and_return(terminal_id)
      allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_USERNAME').and_return(username)
      allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_PASSWORD').and_return(password)
      allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_BASE_URL').and_return(base_url)
      allow(ENV).to receive(:fetch).with('SIX_SAFERPAY_CSS_URL').and_return(css_url)
    end

    describe '#initialize_payment' do
      let(:saferpay_billing_address) do
        instance_double("SixSaferpay::Address",
          first_name: order.billing_address.first_name,
          last_name: order.billing_address.last_name,
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
          email: nil,)
      end

      let(:saferpay_shipping_address) do
        instance_double("SixSaferpay::Address",
          first_name: order.shipping_address.first_name,
          last_name: order.shipping_address.last_name,
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
          email: nil,)
      end

      let(:saferpay_amount) do
        instance_double("SixSaferpay::Amount",
          value: (order.total * 100),
          currency_code: order.currency)
      end

      let(:saferpay_payment) do
        instance_double("SixSaferpay::Payment",
          amount: saferpay_amount,
          order_id: order.number,
          description: order.number)
      end

      let(:saferpay_payer) do
        instance_double("SixSaferpay::Payer",
          language_code: I18n.locale,
          billing_address: saferpay_billing_address,
          delivery_address: saferpay_shipping_address)
      end

      let(:return_urls) do
        instance_double("SixSaferpay::ReturnUrls",
          success: solidus_six_saferpay_transaction_success_url(order),
          fd_fail: solidus_six_saferpay_transaction_fail_url(order),
          fd_abort: solidus_six_saferpay_transaction_fail_url(order),)
      end

      let(:initialize_params) do
        {
          payment: saferpay_payment,
          payer: saferpay_payer,
          return_urls: return_urls
        }
      end

      let(:saferpay_initialize) do
        instance_double("SixSaferpay::SixTransaction::Initialize")
      end

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

      it 'initializes a payment page payment' do
        # mock payment
        expect(SixSaferpay::Amount).to receive(:new).with(
          value: (order.total * 100),
          currency_code: order.currency
        ).and_return(saferpay_amount)
        expect(SixSaferpay::Payment).to receive(:new).with(
          amount: saferpay_amount,
          order_id: order.number,
          description: order.number
        ).and_return(saferpay_payment)

        # mock payer
        expect(SixSaferpay::Address).to receive(:new).with(
          first_name: order.billing_address.first_name,
          last_name: order.billing_address.last_name,
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
          email: nil,
        ).and_return(saferpay_billing_address)
        expect(SixSaferpay::Address).to receive(:new).with(
          first_name: order.shipping_address.first_name,
          last_name: order.shipping_address.last_name,
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
          email: nil,
        ).and_return(saferpay_shipping_address)
        expect(SixSaferpay::Payer).to receive(:new).with(
          language_code: I18n.locale,
          billing_address: saferpay_billing_address,
          delivery_address: saferpay_shipping_address
        ).and_return(saferpay_payer)

        # mock return_urls
        expect(SixSaferpay::ReturnUrls).to receive(:new).with(
          success: solidus_six_saferpay_transaction_success_url(order),
          fd_fail: solidus_six_saferpay_transaction_fail_url(order),
          fd_abort: solidus_six_saferpay_transaction_fail_url(order),
        ).and_return(return_urls)

        expect(SixSaferpay::SixTransaction::Initialize).to receive(:new).with(initialize_params).and_return(saferpay_initialize)

        expect(SixSaferpay::Client).to receive(:post).with(saferpay_initialize).and_return(api_initialize_response)

        gateway.initialize_payment(order, payment_method)
      end

      context 'when the payment initialization is successful' do
        before do
          expect(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Initialize)).and_return(api_initialize_response)
        end

        it 'returns a success gateway response' do
          expect(GatewayResponse).to receive(:new).with(true, instance_of(String), api_initialize_response, {})
          gateway.initialize_payment(order, payment_method)
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
          expect(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Initialize)).and_raise(six_saferpay_error)
        end

        it 'handles the error gracefully' do
          expect(GatewayResponse).to receive(:new).with(false, six_saferpay_error.error_message, nil,
            error_name: six_saferpay_error.error_name)

          gateway.initialize_payment(order, payment_method)
        end
      end
    end

    describe '#inquire' do
      let(:saferpay_inquire) do
        instance_double("SixSaferpay::SixTransaction::Inquire")
      end

      let(:transaction_status) { "AUTHORIZED" }
      let(:transaction_id) { "723n4MAjMdhjSAhAKEUdA8jtl9jb" }
      let(:transaction_date) { "2015-01-30T12:45:22.258+01:00" }
      let(:amount_value) { "100" }
      let(:amount_currency) { "USD" }
      let(:brand_name) { 'PaymentBrand' }
      let(:display_text) { "xxxx xxxx xxxx 1234" }
      let(:six_transaction_reference) { "0:0:3:723n4MAjMdhjSAhAKEUdA8jtl9jb" }

      let(:payment_means) do
        SixSaferpay::ResponsePaymentMeans.new(
          brand: SixSaferpay::Brand.new(name: brand_name),
          display_text: display_text
        )
      end

      let(:api_inquire_response) do
        SixSaferpay::SixTransaction::InquireResponse.new(
          response_header: SixSaferpay::ResponseHeader.new(request_id: 'test', spec_version: 'test'),
          transaction: SixSaferpay::Transaction.new(
            type: "PAYMENT",
            status: transaction_status,
            id: transaction_id,
            date: transaction_date,
            amount: SixSaferpay::Amount.new(value: amount_value, currency_code: amount_currency),
            six_transaction_reference: six_transaction_reference,
          ),
          payment_means: payment_means
        )
      end

      it 'performs an inquire request' do
        expect(SixSaferpay::SixTransaction::Inquire).to receive(:new).with(transaction_reference: payment.transaction_id).and_return(saferpay_inquire)
        expect(SixSaferpay::Client).to receive(:post).and_return(api_inquire_response)

        gateway.inquire(payment)
      end

      context 'when the payment inquiry is successful' do
        before do
          allow(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Inquire)).and_return(api_inquire_response)
        end

        it 'returns a successful gateway response' do
          expect(GatewayResponse).to receive(:new).with(true, instance_of(String), api_inquire_response, {})

          gateway.inquire(payment)
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
          allow(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Inquire)).and_raise(six_saferpay_error)
        end

        it 'handles the error gracefully' do
          expect(GatewayResponse).to receive(:new).with(false, six_saferpay_error.error_message, nil,
            error_name: six_saferpay_error.error_name)

          gateway.inquire(payment)
        end
      end
    end

    describe '#authorize' do
      let(:saferpay_authorize) do
        instance_double("SixSaferpay::Transaction::Authorize")
      end

      let(:transaction_status) { "AUTHORIZED" }
      let(:transaction_id) { "723n4MAjMdhjSAhAKEUdA8jtl9jb" }
      let(:transaction_date) { "2015-01-30T12:45:22.258+01:00" }
      let(:amount_value) { "100" }
      let(:amount_currency) { "USD" }
      let(:brand_name) { 'PaymentBrand' }
      let(:display_text) { "xxxx xxxx xxxx 1234" }
      let(:six_transaction_reference) { "0:0:3:723n4MAjMdhjSAhAKEUdA8jtl9jb" }

      let(:payment_means) do
        SixSaferpay::ResponsePaymentMeans.new(
          brand: SixSaferpay::Brand.new(name: brand_name),
          display_text: display_text
        )
      end

      let(:api_authorize_response) do
        SixSaferpay::SixTransaction::AuthorizeResponse.new(
          response_header: SixSaferpay::ResponseHeader.new(request_id: 'test', spec_version: 'test'),
          transaction: SixSaferpay::Transaction.new(
            type: "PAYMENT",
            status: transaction_status,
            id: transaction_id,
            date: transaction_date,
            amount: SixSaferpay::Amount.new(value: amount_value, currency_code: amount_currency),
            six_transaction_reference: six_transaction_reference,
          ),
          payment_means: payment_means
        )
      end

      it 'performs an authorize request' do
        expect(SixSaferpay::SixTransaction::Authorize).to receive(:new).with(token: payment.token).and_return(saferpay_authorize)
        expect(SixSaferpay::Client).to receive(:post).and_return(api_authorize_response)

        gateway.authorize(payment.order.total, payment)
      end

      context 'when the payment authorize is successful' do
        before do
          allow(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Authorize)).and_return(api_authorize_response)
        end

        it 'returns a successful gateway response' do
          expect(GatewayResponse).to receive(:new).with(true, instance_of(String), api_authorize_response, {})

          gateway.authorize(payment.order.total, payment)
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
          allow(SixSaferpay::Client).to receive(:post).with(instance_of(SixSaferpay::SixTransaction::Authorize)).and_raise(six_saferpay_error)
        end

        it 'handles the error gracefully' do
          expect(GatewayResponse).to receive(:new).with(false, six_saferpay_error.error_message, nil,
            error_name: six_saferpay_error.error_name)

          gateway.authorize(payment.order.total, payment)
        end
      end
    end
  end
end
