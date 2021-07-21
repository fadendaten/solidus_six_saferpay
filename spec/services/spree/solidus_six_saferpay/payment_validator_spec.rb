require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe PaymentValidator do
      subject(:service) { described_class.new(payment) }

      let(:payment) { create(:six_saferpay_payment, :authorized) }

      describe '.call' do
        it 'calls an initialized service with given saferpay payment' do
          allow(described_class).to receive(:new).with(payment).and_return(service)
          allow(service).to receive(:call)

          described_class.call(payment)

          expect(service).to have_received(:call)
        end
      end

      describe '#call' do
        before do
          allow(service).to receive(:validate_order_reference)
          allow(service).to receive(:validate_order_amount)
          allow(service).to receive(:validate_payment_authorized)
        end

        it 'validates authorization' do
          service.call
          expect(service).to have_received(:validate_payment_authorized).with(payment.transaction)
        end

        it 'validates order reference' do
          service.call
          expect(service).to have_received(:validate_order_reference).with(payment.transaction)
        end

        it 'validates order amount' do
          service.call
          expect(service).to have_received(:validate_order_amount).with(payment.transaction)
        end
      end

      describe '#validate_payment_authorized' do
        let(:saferpay_transaction) { instance_double('SixSaferpay::Transaction', status: 'AUTHORIZED') }

        context 'when the saferpay status is AUTHORIZED' do
          it 'passes validation' do
            expect(service.validate_payment_authorized(saferpay_transaction)).to be true
          end
        end

        context 'when the saferpay status is CAPTURED' do
          let(:saferpay_transaction) { instance_double('SixSaferpay::Transaction', status: 'CAPTURED') }

          it 'raises an error' do
            expect{
              service.validate_payment_authorized(saferpay_transaction)
            }.to raise_error(::SolidusSixSaferpay::InvalidSaferpayPayment)
          end
        end

        context 'when the saferpay status is PENDING' do
          let(:saferpay_transaction) { instance_double("SixSaferpay::Transaction", status: "PENDING") }

          it 'raises an error' do
            expect{
              service.validate_payment_authorized(saferpay_transaction)
            }.to raise_error(::SolidusSixSaferpay::InvalidSaferpayPayment)
          end
        end
      end

      describe '#validate_order_reference' do
        context 'when the saferpay order reference matches the solidus order' do
          let(:saferpay_transaction) { instance_double("SixSaferpay::Transaction", order_id: payment.order.number) }

          it 'passes validation' do
            expect(service.validate_order_reference(saferpay_transaction)).to be true
          end
        end

        context 'when the saferpay order reference does not match the solidus order' do
          let(:saferpay_transaction) { instance_double("SixSaferpay::Transaction", order_id: "OTHER") }

          it 'raises an error' do
            expect{
              service.validate_order_reference(saferpay_transaction)
            }.to raise_error(::SolidusSixSaferpay::InvalidSaferpayPayment)
          end
        end
      end

      describe '#validate_order_amount' do
        let(:saferpay_transaction) { instance_double("SixSaferpay::Transaction", amount: saferpay_amount) }

        context 'when the saferpay payment values match the solidus order values' do
          let(:saferpay_amount) {
            instance_double("SixSaferpay::Amount", value: (payment.order.amount * 100).to_s,
           currency_code: payment.order.currency)
          }

          it 'passes validation' do
            expect(service.validate_order_amount(saferpay_transaction)).to be true
          end
        end

        context 'when the saferpay payment currency does not match the solidus order currency' do
          let(:saferpay_amount) {
            instance_double("SixSaferpay::Amount", value: (payment.order.amount * 100).to_s, currency_code: "OTHER")
          }

          it 'raises an error' do
            expect{
              service.validate_order_amount(saferpay_transaction)
            }.to raise_error(::SolidusSixSaferpay::InvalidSaferpayPayment)
          end
        end

        context 'when the saferpay payment value does not match the solidus order value' do
          let(:saferpay_amount) {
            instance_double("SixSaferpay::Amount", value: ((payment.order.amount + 5) * 100).to_s,
           currency_code: payment.order.currency)
          }

          it 'raises an error' do
            expect{
              service.validate_order_amount(saferpay_transaction)
            }.to raise_error(::SolidusSixSaferpay::InvalidSaferpayPayment)
          end
        end
      end
    end
  end
end
