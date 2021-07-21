require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe CancelAuthorizedPayment do
      subject(:service) { described_class.new(payment) }

      describe '.call' do
        let(:payment) { create(:six_saferpay_payment) }

        it 'calls an initialized service with given order and payment method' do
          allow(described_class).to receive(:new).with(payment).and_return(service)
          allow(service).to receive(:call)

          described_class.call(payment)
          expect(service).to have_received(:call)
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
            allow(gateway).to receive(:void)

            service.call

            expect(gateway).not_to have_received(:void)
          end

          it 'is treated as an error' do
            allow(::SolidusSixSaferpay::ErrorHandler).to receive(:handle)

            service.call

            expect(::SolidusSixSaferpay::ErrorHandler).to have_received(:handle).with(
              instance_of(::SolidusSixSaferpay::InvalidSaferpayPayment)
            )
          end
        end

        context 'when the payment has been authorized already' do
          let(:payment) { create(:six_saferpay_payment, :authorized) }

          it 'voids the payment' do
            allow(gateway).to receive(:void)

            service.call

            expect(gateway).to have_received(:void).with(payment.transaction_id)
          end
        end
      end
    end
  end
end
