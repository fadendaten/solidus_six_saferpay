RSpec.shared_examples "it uses the payment page gateway" do
  it_behaves_like "it has route access"

  describe '#gateway' do
    it 'configures the gateway urls correctly' do
      expect(::SolidusSixSaferpay::PaymentPageGateway).to receive(:new)

      subject.gateway
    end

    context 'when the gateway is configured correctly' do
      before do
        allow(ENV).to receive(:fetch).with("SIX_SAFERPAY_CUSTOMER_ID").and_return("customer_id")
        allow(ENV).to receive(:fetch).with("SIX_SAFERPAY_TERMINAL_ID").and_return("terminal_id")
        allow(ENV).to receive(:fetch).with("SIX_SAFERPAY_USERNAME").and_return("username")
        allow(ENV).to receive(:fetch).with("SIX_SAFERPAY_PASSWORD").and_return("password")
        allow(ENV).to receive(:fetch).with("SIX_SAFERPAY_BASE_URL").and_return("base_url")
        allow(ENV).to receive(:fetch).with("SIX_SAFERPAY_CSS_URL").and_return("css_url")
      end

      it 'returns a PaymentPageGateway' do
        expect(subject.gateway).to be_a(::SolidusSixSaferpay::PaymentPageGateway)
      end
    end
  end
end
