module SolidusSixSaferpay
  RSpec.describe LineItemTypeDeductor do
    subject(:service) { described_class.new(line_item) }

    let(:line_item) { instance_double(Spree::LineItem) }

    describe '#type' do
      it 'always returns "PHYSICAL"' do
        expect(service.type).to eq('PHYSICAL')
      end
    end
  end
end
