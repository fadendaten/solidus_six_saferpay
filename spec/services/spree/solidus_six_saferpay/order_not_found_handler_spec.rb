require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe OrderNotFoundHandler do
      subject(:handler) { described_class.new(controller_context: controller, order_number: order_number) }

      let(:controller) { instance_double('SolidusSixSaferpay::CheckoutController') }
      let(:order_number) { "R123445678" }

      describe '.call' do
        it 'calls a new instance with given parameters' do
          allow(described_class).to receive(:new).with(
            controller_context: controller,
            order_number: order_number
          ).and_return(handler)

          allow(handler).to receive(:call)

          described_class.call(controller_context: controller, order_number: order_number)

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
