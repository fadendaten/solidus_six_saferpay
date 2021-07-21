require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe ProcessAuthorizedPayment do
      subject(:service) { described_class.new(payment) }

      let(:payment) { create(:six_saferpay_payment, :authorized) }

      describe '.call' do
        it 'calls an initialized service with given order and payment method' do
          allow(described_class).to receive(:new).and_return(service)
          allow(service).to receive(:call)

          described_class.call(payment)

          expect(service).to have_received(:call)
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
          expect(service).not_to be_success
        end
      end
    end
  end
end
