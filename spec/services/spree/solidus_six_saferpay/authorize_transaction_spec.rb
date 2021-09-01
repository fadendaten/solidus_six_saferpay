require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe AuthorizeTransaction do
      subject { described_class.new(payment) }

      let(:payment) { create(:six_saferpay_payment) }

      describe '#gateway' do
        it_behaves_like "it uses the transaction gateway"
      end

      describe '#call' do
        let(:api_response_class) { SixSaferpay::SixTransaction::AuthorizeResponse }

        it_behaves_like "authorize_payment"
      end
    end
  end
end
