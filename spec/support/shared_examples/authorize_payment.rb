RSpec.shared_examples 'authorize_payment' do
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

  # https://saferpay.github.io/jsonapi/#Payment_v1_PaymentPage_Assert
  # https://saferpay.github.io/jsonapi/#Payment_v1_Transaction_Authorize
  let(:api_response) do
    api_response_class.new(
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

  let(:gateway_response) do
    ::SolidusSixSaferpay::GatewayResponse.new(
      gateway_success,
      "initialize success: #{gateway_success}",
      api_response
    )
  end

  # stub gateway to return our mock response
  before do
    allow(subject).to receive(:gateway).
      and_return(double('gateway', authorize: gateway_response))
  end

  context 'when not successful' do
    let(:gateway_success) { false }

    it 'indicates failure' do
      subject.call

      expect(subject).not_to be_success
    end

    it 'does not update the payment attributes' do
      expect { subject.call }.not_to change(payment, :transaction_id)
      expect { subject.call }.not_to change(payment, :transaction_status)
      expect { subject.call }.not_to change(payment, :transaction_date)
      expect { subject.call }.not_to change(payment, :six_transaction_reference)
      expect { subject.call }.not_to change(payment, :display_text)
      expect { subject.call }.not_to change(payment, :response_hash)
    end
  end

  context 'when successful' do
    let(:gateway_success) { true }

    it 'updates the transaction_id' do
      expect { subject.call }.to change(payment, :transaction_id).from(nil).to(transaction_id)
    end

    it 'updates the transaction status' do
      expect { subject.call }.to change(payment, :transaction_status).from(nil).to(transaction_status)
    end

    it 'updates the transaction date' do
      expect { subject.call }.to change(payment, :transaction_date).from(nil).to(DateTime.parse(transaction_date))
    end

    it 'updates the six_transaction_reference' do
      expect { subject.call }.to change(payment, :six_transaction_reference).from(nil).to(six_transaction_reference)
    end

    it 'updates the display_text' do
      expect { subject.call }.to change(payment, :display_text).from(nil).to(display_text)
    end

    it 'updates the response hash' do
      expect { subject.call }.to change(payment, :response_hash).from(payment.response_hash).to(api_response.to_h)
    end

    context 'when the payment was made with a card' do
      let(:masked_number) { "xxxx xxxx xxxx 5555" }
      let(:exp_year) { "19" }
      let(:exp_month) { "5" }
      let(:payment_means) do
        SixSaferpay::ResponsePaymentMeans.new(
          brand: SixSaferpay::Brand.new(name: brand_name),
          display_text: display_text,
          card: SixSaferpay::ResponseCard.new(
            masked_number: masked_number,
            exp_year: exp_year,
            exp_month: exp_month
          )
        )
      end

      it 'updates the masked number' do
        expect { subject.call }.to change(payment, :masked_number).from(nil).to(masked_number)
      end

      it 'updates the expiry year' do
        expect { subject.call }.to change(payment, :expiration_year).from(nil).to(exp_year)
      end

      it 'updates the expiry month' do
        expect { subject.call }.to change(payment, :expiration_month).from(nil).to(exp_month)
      end
    end

    it 'indicates success' do
      subject.call

      expect(subject).to be_success
    end
  end
end
