RSpec.shared_examples 'inquire_payment' do
  before do
    allow(SolidusSixSaferpay::Gateway).to receive(:new).and_return(
      instance_double('SolidusSixSaferpay::Gateway', inquire: gateway_response)
    )
  end

  context 'when gateway response is not successful' do
    let(:error_name) { "VALIDATION_FAILED" }
    let(:api_response) { nil }

    let(:gateway_response) do
      ::SolidusSixSaferpay::GatewayResponse.new(
        false,
        "initialize success: false",
        api_response,
        error_name: error_name,
      )
    end

    it 'still indicates success' do
      subject.call

      expect(subject).to be_success
    end

    it 'adds the error message to the response hash' do
      expect { subject.call }.to change(payment, :response_hash).from({}).to({ error: error_name })
    end

    it 'sets the user message according to the api error code' do
      allow(I18n).to receive(:t).with(:general_error,
        scope: [:solidus_six_saferpay, :errors]).once.and_return("General Error Message")
      allow(I18n).to receive(:t).with(error_name,
        scope: [:six_saferpay, :error_names]).once.and_return("User Message")

      subject.call

      expect(subject.user_message).to eq("General Error Message: User Message")
    end
  end

  context 'when gateway response is successful' do
    let(:payment_means) do
    end

    # https://saferpay.github.io/jsonapi/#Payment_v1_PaymentPage_Assert
    # https://saferpay.github.io/jsonapi/#Payment_v1_Transaction_Authorize
    let(:api_response) do
      api_response_class.new(
        response_header: SixSaferpay::ResponseHeader.new(request_id: 'test', spec_version: 'test'),
        transaction: SixSaferpay::Transaction.new(
          type: 'PAYMENT',
          status: 'AUTHORIZED',
          id: 'FAKE_TRANSACTION_ID',
          date: '2015-01-30T12:45:22.258+01:00',
          amount: SixSaferpay::Amount.new(value: '100', currency_code: 'USD'),
          six_transaction_reference: 'FAKE_TRANSACTION_REFERENCE',
        ),
        payment_means: SixSaferpay::ResponsePaymentMeans.new(
          brand: SixSaferpay::Brand.new(name: "PaymentBrand"),
          display_text: "xxxx xxxx xxxx 1234",
        )
      )
    end

    let(:gateway_response) do
      ::SolidusSixSaferpay::GatewayResponse.new(
        true,
        "initialize success: true",
        api_response
      )
    end

    it 'updates the transaction_id' do
      expect { subject.call }.to change(payment, :transaction_id).from(nil).to("FAKE_TRANSACTION_ID")
    end

    it 'updates the transaction status' do
      expect { subject.call }.to change(payment, :transaction_status).from(nil).to("AUTHORIZED")
    end

    it 'updates the transaction date' do
      expect { subject.call }.to change(payment, :transaction_date).from(nil).to(
        DateTime.parse("2015-01-30T12:45:22.258+01:00").in_time_zone(Time.zone)
      )
    end

    it 'updates the six_transaction_reference' do
      expect { subject.call }.to change(payment, :six_transaction_reference).from(nil).to('FAKE_TRANSACTION_REFERENCE')
    end

    it 'updates the display_text' do
      expect { subject.call }.to change(payment, :display_text).from(nil).to("xxxx xxxx xxxx 1234")
    end

    it 'updates the response hash' do
      expect { subject.call }.to change(payment, :response_hash).from(payment.response_hash).to(api_response.to_h)
    end

    it 'indicates success' do
      subject.call

      expect(subject).to be_success
    end
  end
end
