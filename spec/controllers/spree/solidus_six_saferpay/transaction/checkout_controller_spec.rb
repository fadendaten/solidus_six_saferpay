require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe Transaction::CheckoutController do
      let(:initialize_payment_service_class) { InitializeTransaction }
      let(:authorize_payment_service_class) { AuthorizeTransaction }
      let(:process_authorization_service_class) { ProcessTransactionPayment }
      let(:inquire_payment_service_class) { InquireTransactionPayment }

      it_behaves_like "checkout_controller"
    end
  end
end
