require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe InitializePayment do
      let(:order) { create(:order) }
      let(:payment_method) { create(:saferpay_payment_method) }

      let(:service) { described_class.new(order, payment_method) }

      describe '.call' do
        it 'calls an initialized service with given order and payment method' do
          expect(described_class).to receive(:new).with(order, payment_method).and_return(service)
          expect(service).to receive(:call)

          described_class.call(order, payment_method)
        end
      end

      describe '#call' do
        it 'fails because gateway raises an error' do
          expect { service.call }.to raise_error(NotImplementedError)
        end
      end

      describe '#gateway' do
        it 'raises an error because the gateway must be defined in subclasses' do
          expect { service.gateway }.to raise_error(NotImplementedError)
        end
      end

      describe '#success?' do
        it 'is initially false' do
          expect(service.success).to be false
        end
      end
    end
  end
end
