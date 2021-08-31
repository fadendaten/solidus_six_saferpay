# frozen_string_literal: true

module SolidusSixSaferpay
  RSpec.describe AddressNameExtractor do
    subject(:service) { described_class.new(address) }

    context 'when solidus uses a combined name in address' do
      let(:address) { double('Spree::Address', id: 1, name: 'John Von Doe') }

      before do
        allow(SolidusSupport).to receive(:combined_first_and_last_name_in_address?).and_return(true)
      end

      context 'when Address implementation supports #first_name and #last_name' do
        before do
          allow(address).to receive(:first_name).and_return('John')
          allow(address).to receive(:last_name).and_return('Von Doe')
        end

        describe '#first_name' do
          it 'respects these attributes' do
            expect(service.first_name).to eq('John')
          end
        end

        describe '#last_name' do
          it 'respects these attributes' do
            expect(service.last_name).to eq('Von Doe')
          end
        end
      end

      context 'when Address implementation supports #firstname and #lastname' do
        before do
          allow(address).to receive(:firstname).and_return('John')
          allow(address).to receive(:lastname).and_return('Von Doe')
        end

        describe '#first_name' do
          it 'respects these attributes' do
            expect(service.first_name).to eq('John')
          end
        end

        describe '#last_name' do
          it 'respects these attributes' do
            expect(service.last_name).to eq('Von Doe')
          end
        end
      end

      context 'when Address implementation does not support seperate first- and lastname attributes' do
        before do
          allow(address).to receive(:name).and_return('John Von Doe')
        end

        context 'when unsafe name extraction is enabled' do
          before do
            allow(SolidusSixSaferpay.config).to receive(:allow_unsafe_address_name_extraction).and_return(true)
          end

          describe '#first_name' do
            it 'is extracted from name' do
              expect(service.first_name).to eq('John')
            end
          end

          describe '#last_name' do
            it 'is extracted from name' do
              expect(service.last_name).to eq('Von Doe')
            end
          end

        end

        context 'when unsafe name extraction is disabled' do
          before do
            allow(SolidusSixSaferpay.config).to receive(:allow_unsafe_address_name_extraction).and_return(false)
          end

          describe '#first_name' do
            it 'throws an error' do
              expect { service.first_name }.to raise_error(AddressNameExtractor::UnsafeNameExtractionError)
            end
          end

          describe '#last_name' do
            it 'throws an error' do
              expect { service.first_name }.to raise_error(AddressNameExtractor::UnsafeNameExtractionError)
            end
          end
        end
      end
    end

    context 'when solidus does not use a combined name in address' do
      let(:address) { double('Spree::Address') }

      before do
        allow(SolidusSupport).to receive(:combined_first_and_last_name_in_address?).and_return(false)
      end

      describe '#first_name' do
        it 'is delegated to given address instance' do
          allow(address).to receive(:first_name)
          service.first_name

          expect(address).to have_received(:first_name)
        end
      end

      describe '#last_name' do
        it 'is delegated to given address instance' do
          allow(address).to receive(:last_name)
          service.last_name

          expect(address).to have_received(:last_name)
        end
      end
    end
  end
end
