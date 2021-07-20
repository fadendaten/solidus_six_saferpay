RSpec.shared_examples "it uses the transaction gateway" do
  it_behaves_like "it has route access"

  before do
    allow(ENV).to receive(:fetch).with("SIX_SAFERPAY_CUSTOMER_ID").and_return("customer_id")
    allow(ENV).to receive(:fetch).with("SIX_SAFERPAY_TERMINAL_ID").and_return("terminal_id")
    allow(ENV).to receive(:fetch).with("SIX_SAFERPAY_USERNAME").and_return("username")
    allow(ENV).to receive(:fetch).with("SIX_SAFERPAY_PASSWORD").and_return("password")
    allow(ENV).to receive(:fetch).with("SIX_SAFERPAY_BASE_URL").and_return("base_url")
    allow(ENV).to receive(:fetch).with("SIX_SAFERPAY_CSS_URL").and_return("css_url")
  end

  describe '#gateway' do
    it 'configures the gateway urls correctly' do
      allow(::SolidusSixSaferpay::TransactionGateway).to receive(:new)
      subject.gateway
      expect(::SolidusSixSaferpay::TransactionGateway).to have_received(:new)
    end

    context 'when the gateway is configured correctly' do
      it 'returns a TransactionGateway' do
        expect(subject.gateway).to be_a(::SolidusSixSaferpay::TransactionGateway)
      end
    end
  end
end
