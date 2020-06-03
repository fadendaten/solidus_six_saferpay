require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe ProcessTransactionPayment do

      let(:payment) { create(:six_saferpay_payment, :authorized) }

      subject { described_class.new(payment) }

      describe '#gateway' do
        it_behaves_like "it uses the transaction gateway"
      end

      describe '#call' do
        it_behaves_like 'process_authorized_payment'
      end
    end
  end
end
