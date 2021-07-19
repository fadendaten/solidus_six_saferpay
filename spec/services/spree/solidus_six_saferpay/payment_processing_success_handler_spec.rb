require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe PaymentProcessingSuccessHandler do
      subject { described_class.new(controller_context: controller, order: order) }

      let(:controller) { instance_double(SolidusSixSaferpay::CheckoutController) }
      let(:order) { instance_double(Spree::Order, number: "R12345678") }

      describe '.call' do
        it 'calls a new instance with given parameters' do
          expect(described_class).to receive(:new).with(controller_context: controller,
            order: order).and_return(subject)
          expect(subject).to receive(:call)

          described_class.call(controller_context: controller, order: order)
        end
      end

      describe '#call' do
        context 'when the order is in payment state' do
          let(:order) { instance_double(Spree::Order, number: "R12345678", payment?: true) }

          it 'advances the order to the next state' do
            expect(order).to receive(:next!)

            subject.call
          end
        end
      end
    end
  end
end
