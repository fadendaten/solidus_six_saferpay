RSpec.shared_examples 'authorize_payment' do
  let(:amount_value) { "100" }
  let(:amount_currency) { "USD" }

  let(:payment_means) do
    SixSaferpay::ResponsePaymentMeans.new(
      brand: SixSaferpay::Brand.new(name: 'PaymentBrand'),
      display_text: 'xxxx xxxx xxxx 1234',
    )
  end

  # https://saferpay.github.io/jsonapi/#Payment_v1_PaymentPage_Assert
  # https://saferpay.github.io/jsonapi/#Payment_v1_Transaction_Authorize
  let(:api_response) do
    api_response_class.new(
      response_header: SixSaferpay::ResponseHeader.new(request_id: 'test', spec_version: 'test'),
      transaction: SixSaferpay::Transaction.new(
        type: "PAYMENT",
        status: 'AUTHORIZED',
        id: '723n4MAjMdhjSAhAKEUdA8jtl9jb',
        date: '2015-01-30T12:45:22.258+01:00',
        amount: SixSaferpay::Amount.new(value: amount_value, currency_code: amount_currency),
        six_transaction_reference: '0:0:3:723n4MAjMdhjSAhAKEUdA8jtl9jb',
      ),
      payment_means: payment_means
    )
  end

  # stub gateway to return our mock response
  before do
    allow(SolidusSixSaferpay::Gateway).to receive(:new).
      and_return(instance_double('SolidusSixSaferpay::Gateway', authorize: gateway_response))
  end

  context 'when not successful' do
    let(:gateway_response) do
      ::SolidusSixSaferpay::GatewayResponse.new(
        false,
        "initialize success: false",
        api_response
      )
    end

    it 'indicates failure' do
      subject.call

      expect(subject).not_to be_success
    end

    it 'does not update the transaction id' do
      expect { subject.call }.not_to change(payment, :transaction_id)
    end

    it 'does not update the transaction status' do
      expect { subject.call }.not_to change(payment, :transaction_status)
    end

    it 'does not update the transaction date' do
      expect { subject.call }.not_to change(payment, :transaction_date)
    end

    it 'does not update the transaction reference' do
      expect { subject.call }.not_to change(payment, :six_transaction_reference)
    end

    it 'does not update the display text' do
      expect { subject.call }.not_to change(payment, :display_text)
    end

    it 'does not update the response hash' do
      expect { subject.call }.not_to change(payment, :response_hash)
    end
  end

  context 'when successful' do
    let(:gateway_response) do
      ::SolidusSixSaferpay::GatewayResponse.new(
        true,
        "initialize success: true",
        api_response
      )
    end

    it 'updates the transaction_id' do
      expect { subject.call }.to change(payment, :transaction_id).from(nil).to('723n4MAjMdhjSAhAKEUdA8jtl9jb')
    end

    it 'updates the transaction status' do
      expect { subject.call }.to change(payment, :transaction_status).from(nil).to('AUTHORIZED')
    end

    it 'updates the transaction date' do
      expect { subject.call }.to change(payment, :transaction_date).from(nil).to(
        DateTime.parse('2015-01-30T12:45:22.258+01:00')
      )
    end

    it 'updates the six_transaction_reference' do
      expect { subject.call }.to change(payment, :six_transaction_reference).from(nil).to(
        '0:0:3:723n4MAjMdhjSAhAKEUdA8jtl9jb'
      )
    end

    it 'updates the display_text' do
      expect { subject.call }.to change(payment, :display_text).from(nil).to('xxxx xxxx xxxx 1234')
    end

    it 'updates the response hash' do
      expect { subject.call }.to change(payment, :response_hash).from(payment.response_hash).to(api_response.to_h)
    end

    context 'when the payment was made with a card' do
      let(:payment_means) do
        SixSaferpay::ResponsePaymentMeans.new(
          brand: SixSaferpay::Brand.new(name: 'PaymentBrand'),
          display_text: 'xxxx xxxx xxxx 1234',
          card: SixSaferpay::ResponseCard.new(
            masked_number: 'xxxx xxxx xxxx 1234',
            exp_year: '19',
            exp_month: '5'
          )
        )
      end

      it 'updates the masked number' do
        expect { subject.call }.to change(payment, :masked_number).from(nil).to('xxxx xxxx xxxx 1234')
      end

      it 'updates the expiry year' do
        expect { subject.call }.to change(payment, :expiration_year).from(nil).to('19')
      end

      it 'updates the expiry month' do
        expect { subject.call }.to change(payment, :expiration_month).from(nil).to('5')
      end
    end

    it 'indicates success' do
      subject.call

      expect(subject).to be_success
    end
  end
end
