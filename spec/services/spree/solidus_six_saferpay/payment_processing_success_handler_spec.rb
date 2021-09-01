require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe PaymentProcessingSuccessHandler do
      subject(:handler) { described_class.new(controller_context: controller, order: order) }

      let(:controller) { instance_double('SolidusSixSaferpay::CheckoutController') }
      let(:order) { instance_double('Spree::Order', number: "R12345678") }

      describe '.call' do
        it 'calls a new instance with given parameters' do
          allow(described_class).to receive(:new).with(
            controller_context: controller,
            order: order
          ).and_return(handler)

          allow(handler).to receive(:call)

          described_class.call(controller_context: controller, order: order)

          expect(handler).to have_received(:call)
        end
      end

      describe '#call' do
        context 'when the order is in payment state' do
          let(:order) { instance_double(Spree::Order, number: "R12345678", payment?: true) }

          it 'advances the order to the next state' do
            allow(order).to receive(:next!)

            handler.call

            expect(order).to have_received(:next!)
          end
        end
      end
    end
  end
end
