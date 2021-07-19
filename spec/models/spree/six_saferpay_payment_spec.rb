require 'rails_helper'

module Spree
  RSpec.describe SixSaferpayPayment, type: :model do
    let(:payment) { FactoryBot.create(:six_saferpay_payment) }

    describe 'associations' do
      it { is_expected.to belong_to :order }
      it { is_expected.to belong_to :payment_method }
    end

    describe 'validations' do
      it { is_expected.to validate_presence_of :token }
      it { is_expected.to validate_presence_of :expiration }
    end

    describe "#create_solidus_payment!" do
      it 'creates a Solidus::Payment with the correct information' do
        expect(Spree::Payment.count).to eq(0)
        solidus_payment = payment.create_solidus_payment!
        expect(Spree::Payment.count).to eq(1)
        expect(solidus_payment.order).to eq(payment.order)
        expect(solidus_payment.payment_method).to eq(payment.payment_method)
        expect(solidus_payment.response_code).to eq(payment.transaction_id)
        expect(solidus_payment.amount).to eq(payment.order.total)
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

        it 'sets the API response attributes correctly' do
          expect(payment.payment_means.brand.payment_method).to eq("MASTERCARD")
          expect(payment.payment_means.brand.name).to eq("MasterCard")
          expect(payment.payment_means.display_text).to eq("xxxx xxxx xxxx 1234")
          expect(payment.payment_means.card.masked_number).to eq("xxxxxxxxxxxx1234")
          expect(payment.payment_means.card.exp_year).to eq(2019)
          expect(payment.payment_means.card.exp_month).to eq(7)
          expect(payment.payment_means.card.holder_name).to eq("John Doe")
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

        it 'sets the API response attributes correctly' do
          expect(payment.transaction.type).to eq("PAYMENT")
          expect(payment.transaction.status).to eq("AUTHORIZED")
          expect(payment.transaction.amount.value).to eq('20000')
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

        it 'sets the API response attributes correctly' do
          expect(payment.liability.liability_shift).to be true
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
