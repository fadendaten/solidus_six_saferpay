require 'rails_helper'

module Spree
  module SolidusSixSaferpay
    RSpec.describe PaymentPage::CheckoutController do

      let(:initialize_payment_service_class) { InitializePaymentPage }
      let(:authorize_payment_service_class) { AssertPaymentPage }
      let(:process_authorization_service_class) { ProcessPaymentPagePayment }
      let(:inquire_payment_service_class) { InquirePaymentPagePayment }

      it_behaves_like "checkout_controller"

    end
  end
end
