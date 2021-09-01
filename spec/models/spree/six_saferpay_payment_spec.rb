require 'rails_helper'

module Spree
  RSpec.describe SixSaferpayPayment, type: :model do
    subject(:payment) { create(:six_saferpay_payment) }

    describe 'associations' do
      it { is_expected.to belong_to :order }
      it { is_expected.to belong_to :payment_method }
    end

    describe 'validations' do
      it { is_expected.to validate_presence_of :token }
      it { is_expected.to validate_presence_of :expiration }
    end

    describe '.current_payment' do
      let(:payment) { create(:six_saferpay_payment, created_at: DateTime.current - 10.minutes) }
      let(:old_payment) { create(:six_saferpay_payment, order: payment.order, created_at: DateTime.current - 1.hour) }
      let(:new_payment) { create(:six_saferpay_payment, order: payment.order, created_at: DateTime.current) }

      before do
        old_payment
        new_payment
      end

      it 'returns the last saferpay payment for given order' do
        expect(described_class.current_payment(payment.order)).to eq(new_payment)
      end
    end

    describe "#create_solidus_payment!" do
      subject(:solidus_payment) { payment.create_solidus_payment! }

      it 'creates a Solidus::Payment' do
        expect { payment.create_solidus_payment! }.to change { Spree::Payment.count }.from(0).to(1)
      end

      it 'persists the order association in the DB' do
        expect(solidus_payment.order).to eq(payment.order)
      end

      it 'persists the payment method association in the DB' do
        expect(solidus_payment.payment_method).to eq(payment.payment_method)
      end

      it 'persists the response code in the DB' do
        expect(solidus_payment.response_code).to eq(payment.transaction_id)
      end

      it 'persists the amount in the DB' do
        expect(solidus_payment.amount).to eq(payment.order.total)
      end

      it 'persists the source association in the DB' do
        expect(solidus_payment.source).to eq(payment)
      end
    end

    describe '#address' do
      it "returns the order's billing address" do
        expect(payment.address).to eq(payment.order.bill_address)
      end
    end

    describe '#payment_means' do
      context 'when the payment is still unprocessed' do
        it 'returns nil' do
          expect(payment.payment_means).to be_nil
        end
      end

      context 'when the payment is authorized' do
        let(:payment) { FactoryBot.create(:six_saferpay_payment, :authorized) }

        it 'returns a SixSaferpay::ResponsePaymentMeans' do
          expect(payment.payment_means).to be_a(SixSaferpay::ResponsePaymentMeans)
        end

        it 'sets the payment method' do
          expect(payment.payment_means.brand.payment_method).to eq("MASTERCARD")
        end

        it 'sets the payment brand' do
          expect(payment.payment_means.brand.name).to eq("MasterCard")
        end

        it 'sets the display text' do
          expect(payment.payment_means.display_text).to eq("xxxx xxxx xxxx 1234")
        end

        it 'sets the masked number' do
          expect(payment.payment_means.card.masked_number).to eq("xxxxxxxxxxxx1234")
        end

        it 'sets the expiration year' do
          expect(payment.payment_means.card.exp_year).to eq(2019)
        end

        it 'sets the expiration month' do
          expect(payment.payment_means.card.exp_month).to eq(7)
        end

        it 'sets the card holder name' do
          expect(payment.payment_means.card.holder_name).to eq("John Doe")
        end

        it 'sets the card holder country' do
          expect(payment.payment_means.card.country_code).to eq("US")
        end
      end
    end

    describe '#transaction' do
      context 'when the payment is still unprocessed' do
        it 'returns nil' do
          expect(payment.transaction).to be_nil
        end
      end

      context 'when the payment is authorized' do
        let(:payment) { FactoryBot.create(:six_saferpay_payment, :authorized) }

        it 'returns a SixSaferpay::Transaction' do
          expect(payment.transaction).to be_a(SixSaferpay::Transaction)
        end

        it 'sets the transaction type' do
          expect(payment.transaction.type).to eq("PAYMENT")
        end

        it 'sets the transaction status' do
          expect(payment.transaction.status).to eq("AUTHORIZED")
        end

        it 'sets the transaction amount' do
          expect(payment.transaction.amount.value).to eq('20000')
        end

        it 'sets the transaction currency' do
          expect(payment.transaction.amount.currency_code).to eq("CHF")
        end
      end
    end

    describe '#liability' do
      context 'when the payment is still unprocessed' do
        it 'returns nil' do
          expect(payment.liability).to be_nil
        end
      end

      context 'when the payment is authorized' do
        let(:payment) { FactoryBot.create(:six_saferpay_payment, :authorized) }

        it 'returns a SixSaferpay::Liability' do
          expect(payment.liability).to be_a(SixSaferpay::Liability)
        end

        it 'sets the liability shift' do
          expect(payment.liability.liability_shift).to be true
        end

        it 'sets the liable entity' do
          expect(payment.liability.liable_entity).to eq("ThreeDs")
        end
      end
    end

    describe '#card' do
      context 'when the payment is still unprocessed' do
        it 'returns nil' do
          expect(payment.card).to be_nil
        end
      end

      context 'when the payment is authorized' do
        let(:payment) { FactoryBot.create(:six_saferpay_payment, :authorized) }

        it 'returns a SixSaferpay::ResponseCard' do
          expect(payment.card).to be_a(SixSaferpay::ResponseCard)
        end
      end
    end

    describe '#name' do
      context 'when the payment is still unprocessed' do
        it 'returns nil' do
          expect(payment.name).to be_nil
        end
      end

      context 'when the payment is authorized' do
        let(:payment) { FactoryBot.create(:six_saferpay_payment, :authorized) }

        it 'returns the card holder name' do
          expect(payment.name).to eq("John Doe")
        end
      end
    end

    describe '#brand_name' do
      context 'when the payment is still unprocessed' do
        it 'returns nil' do
          expect(payment.brand_name).to be_nil
        end
      end

      context 'when the payment is authorized' do
        let(:payment) { FactoryBot.create(:six_saferpay_payment, :authorized) }

        it 'returns the brand name' do
          expect(payment.brand_name).to eq("MasterCard")
        end
      end
    end

    describe '#month' do
      context 'when the payment is still unprocessed' do
        it 'returns nil' do
          expect(payment.month).to be_nil
        end
      end

      context 'when the payment is authorized' do
        let(:payment) { FactoryBot.create(:six_saferpay_payment, :authorized) }

        it 'returns the card expiration month' do
          expect(payment.month).to eq(7)
        end
      end
    end

    describe '#year' do
      context 'when the payment is still unprocessed' do
        it 'returns nil' do
          expect(payment.year).to be_nil
        end
      end

      context 'when the payment is authorized' do
        let(:payment) { FactoryBot.create(:six_saferpay_payment, :authorized) }

        it 'returns the card expiration year' do
          expect(payment.year).to eq(2019)
        end
      end
    end

    describe '#icon_name' do
      context 'when the payment is still unprocessed' do
        it 'returns nil' do
          expect(payment.icon_name).to be_nil
        end
      end

      context 'when the payment is authorized' do
        let(:payment) { FactoryBot.create(:six_saferpay_payment, :authorized) }

        it 'returns a downcased brand name' do
          expect(payment.icon_name).to eq("mastercard")
        end
      end
    end
  end
end
