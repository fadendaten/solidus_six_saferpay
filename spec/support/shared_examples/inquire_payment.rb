RSpec.shared_examples 'inquire_payment' do

  before do
    allow(subject).to receive(:gateway).and_return(double('gateway', inquire: gateway_response))
  end

  context 'when gateway response is not successful' do
    let(:gateway_success) { false }
    let(:error_behaviour) { "ABORT" }
    let(:error_name) { "VALIDATION_FAILED" }
    let(:error_message) { "Request validation failed" }
    let(:api_response) { nil }
    let(:translated_general_error) { "General Error" }
    let(:translated_user_message) { "User Message" }

    let(:gateway_response) do
      ::SolidusSixSaferpay::GatewayResponse.new(
        gateway_success,
        "initialize success: #{gateway_success}",
        api_response,
        error_name: error_name,
      )
    end

    it 'still indicates success' do
      subject.call

      expect(subject).to be_success
    end

    it 'adds the error message to the response hash' do
      expect { subject.call }.to change { payment.response_hash }.from({}).to({error: error_name})
    end

    it 'sets the user message according to the api error code' do
      expect(I18n).to receive(:t).with(:general_error, scope: [:solidus_six_saferpay, :errors]).once.and_return(translated_general_error)
      expect(I18n).to receive(:t).with(error_name, scope: [:six_saferpay, :error_names]).once.and_return(translated_user_message)

      subject.call

      expect(subject.user_message).to eq("#{translated_general_error}: #{translated_user_message}")
    end
  end

  context 'when gateway response is successful' do
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

    let(:gateway_success) { true }
    let(:gateway_response) do
      ::SolidusSixSaferpay::GatewayResponse.new(
        gateway_success,
        "initialize success: #{gateway_success}",
        api_response
      )
    end

    it 'updates the transaction_id' do
      expect { subject.call }.to change { payment.transaction_id }.from(nil).to(transaction_id)
    end

    it 'updates the transaction status' do
      expect { subject.call }.to change { payment.transaction_status }.from(nil).to(transaction_status)
    end

    it 'updates the transaction date' do
      expect { subject.call }.to change { payment.transaction_date }.from(nil).to(DateTime.parse(transaction_date))
    end

    it 'updates the six_transaction_reference' do
      expect { subject.call }.to change { payment.six_transaction_reference }.from(nil).to(six_transaction_reference)
    end

    it 'updates the display_text' do
      expect { subject.call }.to change { payment.display_text }.from(nil).to(display_text)
    end

    it 'updates the response hash' do
      expect { subject.call }.to change { payment.response_hash }.from(payment.response_hash).to(api_response.to_h)
    end

    it 'indicates success' do
      subject.call

      expect(subject).to be_success
    end
  end
end
