require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe InquireTransactionPayment do
      subject { described_class.new(payment) }

      let(:payment) { create(:six_saferpay_payment) }

      describe '#gateway' do
        it_behaves_like "it uses the transaction gateway"
      end

      describe '#call' do
        let(:api_response_class) { SixSaferpay::SixTransaction::InquireResponse }

        it_behaves_like "inquire_payment"
      end
    end
  end
end
