require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe PaymentNotFoundHandler do
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
        it 'informs about the error' do
          allow(::SolidusSixSaferpay::ErrorHandler).to receive(:handle)

          handler.call

          expect(::SolidusSixSaferpay::ErrorHandler).to have_received(:handle).with(instance_of(StandardError))
        end
      end
    end
  end
end
