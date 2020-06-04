require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe ProcessPaymentPagePayment do

      let(:payment) { create(:six_saferpay_payment, :authorized) }

      subject { described_class.new(payment) }

      describe '#gateway' do
        it_behaves_like "it uses the payment page gateway"
      end

      describe '#call' do
        it_behaves_like 'process_authorized_payment'
      end
    end
  end
end
