# frozen_string_literal: true

module SolidusSixSaferpay
  RSpec.describe AddressNameExtractor do
    subject(:service) { described_class.new(address) }

    # This spec is feature-dependant because we are testing over multiple
    # versions with different address factories.
    # If there are smarter ways to do this please open a PR
    if !SolidusSupport.combined_first_and_last_name_in_address?
      let(:address) { create(:address, first_name: 'John', last_name: 'Von Doe') }

      describe '#first_name' do
        it 'delegates to Address#first_name' do
          allow(address).to receive(:first_name)
          service.first_name

          expect(address).to have_received(:first_name)
        end
      end

      describe '#last_name' do
        it 'delegates to Address#last_name' do
          allow(address).to receive(:last_name)
          service.last_name

          expect(address).to have_received(:last_name)
        end
      end
    else
      let(:address) { create(:address, name: 'John Von Doe') }

      context 'when Address has first_name and last_name attributes' do
        before do
          allow(address).to receive(:first_name).and_return('Jon')
          allow(address).to receive(:last_name).and_return('Van Doe')
        end

        describe '#first_name' do
          it 'respects custom Address#first_name attribute' do
            expect(service.first_name).to eq('Jon')
          end
        end

        describe '#last_name' do
          it 'respects custom Address#last_name attribute' do
            expect(service.last_name).to eq('Van Doe')
          end
        end
      end

      context 'when Address has firstname and lastname attributes' do
        before do
          allow(address).to receive(:first_name).and_return('Johnny')
          allow(address).to receive(:last_name).and_return('Doe')
        end

        it 'respects custom Address#firstname attribute' do
          expect(service.first_name).to eq('Johnny')
        end

        it 'respects custom Address#lastname attribute' do
          expect(service.last_name).to eq('Doe')
        end
      end

      context 'when unsafe name extraction from combined names is enabled' do
        before do
          allow(SolidusSixSaferpay.config).to receive(:allow_unsafe_address_name_extraction).and_return(true)
        end

        describe '#first_name' do
          it 'extracts first name from combined name attribute' do
            expect(service.first_name).to eq('John')
          end
        end

        describe '#last_name' do
          it 'extracts last name from combined name attribute' do
            expect(service.last_name).to eq('Von Doe')
          end
        end
      end

      context 'when unsafe name extraction from combined names is disabled for addresses without first- and lastname' do
        before do
          allow(address).to receive(:respond_to?).with(:first_name).and_return(false)
          allow(address).to receive(:respond_to?).with(:firstname).and_return(false)
          allow(SolidusSixSaferpay.config).to receive(:allow_unsafe_address_name_extraction).and_return(false)
        end

        describe '#first_name' do
          it 'throws an error' do
            expect { service.first_name }.to raise_error(AddressNameExtractor::UnsafeNameExtractionError)
          end
        end

        describe '#last_name' do
          it 'throws an error' do
            expect { service.last_name }.to raise_error(AddressNameExtractor::UnsafeNameExtractionError)
          end
        end
      end
    end
  end
end
