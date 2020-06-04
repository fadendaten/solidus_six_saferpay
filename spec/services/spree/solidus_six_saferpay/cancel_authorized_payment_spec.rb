require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe CancelAuthorizedPayment do


      let(:service) { described_class.new(payment) }

      describe '.call' do
        let(:payment) { create(:six_saferpay_payment) }

        it 'calls an initialized service with given order and payment method' do
          expect(described_class).to receive(:new).with(payment).and_return(service)
          expect(service).to receive(:call)

          described_class.call(payment)
        end
      end

      describe '#call' do
        let(:gateway) { instance_double(::SolidusSixSaferpay::Gateway) }

        before do
          allow(service).to receive(:gateway).and_return(gateway)
        end

        context 'when the payment has not been authorized yet' do
          let(:payment) { create(:six_saferpay_payment) }

          it 'does not cancel the payment' do
            expect(gateway).not_to receive(:void)

            service.call
          end

          it 'is treated as an error' do
            expect(::SolidusSixSaferpay::ErrorHandler).to receive(:handle).with(instance_of(::SolidusSixSaferpay::InvalidSaferpayPayment))

            service.call
          end
        end

        context 'when the payment has been authorized already' do
          let(:payment) { create(:six_saferpay_payment, :authorized) }

          it 'voids the payment' do
            expect(gateway).to receive(:void).with(payment.transaction_id)

            service.call
          end

        end
      end

    end
  end
end
