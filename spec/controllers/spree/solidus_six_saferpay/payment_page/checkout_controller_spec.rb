require 'rails_helper'

RSpec.describe Spree::SolidusSixSaferpay::PaymentPage::CheckoutController, type: :controller do
  routes { Spree::Core::Engine.routes }

  let(:user) { create(:user) }
  let(:order) { create(:order) }
  let(:payment_method) { create(:saferpay_payment_method_payment_page) }

  let(:subject) { described_class.new }

  before do
    allow(controller).to receive_messages try_spree_current_user: user
    allow(controller).to receive_messages current_order: order
  end

  describe 'GET init' do
    let(:success) { false }
    let(:redirect_url) { '/saferpay/redirect/url' }
    let(:initialized_payment) { instance_double("Spree::SolidusSixSaferpay::InitializePaymentPage", success?: success, redirect_url: redirect_url) }

    it 'tries to the saferpay payment' do
      expect(Spree::SolidusSixSaferpay::InitializePaymentPage).to receive(:call).with(order, payment_method).and_return(initialized_payment)

      get :init, params: { payment_method_id: payment_method.id }
    end


    context 'when payment initialize succeeds' do
      let(:success) { true }

      before do
        allow(Spree::SolidusSixSaferpay::InitializePaymentPage).to receive(:call).with(order, payment_method).and_return(initialized_payment)
      end

      it 'returns the redirect_url' do
        get :init, params: { payment_method_id: payment_method.id }

        body = JSON.parse(response.body)
        expect(body["redirect_url"]).to eq(redirect_url)
      end
    end

    context 'when payment initialize fails' do
      let(:success) { false }

      before do
        allow(Spree::SolidusSixSaferpay::InitializePaymentPage).to receive(:call).with(order, payment_method).and_return(initialized_payment)
      end

      it 'returns an error' do
        get :init, params: { payment_method_id: payment_method.id }

        expect(response.body).to match(/errors/)
        expect(response.status).to eq(422)
      end
    end

  end

  describe 'GET success' do
    context 'when the order is not found' do
      let(:order) { nil }

      it 'redirects to the cart page via iframe breakout' do
        get :success
        expect(assigns(:redirect_path)).to eq(routes.cart_path)
        expect(response).to render_template :iframe_breakout_redirect
      end
    end

    context 'when the order is already completed' do
      let(:order) { create(:order_ready_to_ship) }

      it 'redirects to the cart page via iframe breakout' do
        get :success
        expect(assigns(:redirect_path)).to eq(routes.cart_path)
        expect(response).to render_template :iframe_breakout_redirect
      end
    end

    context 'when payment could not be created' do
      let!(:payment) { nil }

      it 'raises an error because no payment exists' do
        expect{ get(:success) }.to raise_error(Spree::Core::GatewayError)
      end
    end

    context 'when payment create was successful' do
      let!(:payment) { create(:six_saferpay_payment, order: order) }
      let(:assert_success) { false }
      let(:payment_assert) { instance_double("Spree::SolidusSixSaferpay::AssertPaymentPage", success?: assert_success) }
      let(:payment_inquiry) { instance_double("Spree::SolidusSixSaferpay::InquirePaymentPagePayment", user_message: "payment inquiry message") }

      it 'asserts the payment' do
        expect(Spree::SolidusSixSaferpay::AssertPaymentPage).to receive(:call).with(payment).and_return(payment_assert)
        expect(Spree::SolidusSixSaferpay::InquirePaymentPagePayment).to receive(:call).with(payment).and_return(payment_inquiry)

        get :success
      end

      context 'when the payment assert is successful' do
        let(:assert_success) { true }
        let(:process_success) { false }
        let(:processed_payment) { instance_double("Spree::SolidusSixSaferpay::ProcessPaymentPagePayment", success?: process_success, user_message: "payment processing message") }

        before do
          allow(Spree::SolidusSixSaferpay::AssertPaymentPage).to receive(:call).with(payment).and_return(payment_assert)
        end

        it 'processes the asserted payment' do
          expect(Spree::SolidusSixSaferpay::ProcessPaymentPagePayment).to receive(:call).with(payment).and_return(processed_payment)

          get :success
        end

        context 'when the processing is successful' do
          let(:process_success) { true }

          before do
            allow(Spree::SolidusSixSaferpay::ProcessPaymentPagePayment).to receive(:call).with(payment).and_return(processed_payment)
          end


          context 'when order is in payment state' do
            let(:order) { create(:order, state: :payment) }

            it 'moves order to next state' do
              expect(order).to receive(:next!)

              get :success
            end
          end

          context 'when order is already in complete state' do
            let(:order) { create(:order, state: :complete) }

            it 'does not modify the order state' do
              expect(order).not_to receive(:next!)

              get :success
            end
          end
        end

        context 'when the processing fails' do
          let(:process_success) { false }

          before do
            allow(Spree::SolidusSixSaferpay::ProcessPaymentPagePayment).to receive(:call).with(payment).and_return(processed_payment)
          end

          it 'displays an error message' do
            get :success

            expect(flash[:error]).to eq("payment processing message")
          end
        end

      end

      context 'when the payment assert fails' do
        let(:assert_success) { false }

        before do
          allow(Spree::SolidusSixSaferpay::AssertPaymentPage).to receive(:call).with(payment).and_return(payment_assert)
        end

        it 'inquires the payment' do
          expect(Spree::SolidusSixSaferpay::InquirePaymentPagePayment).to receive(:call).with(payment).and_return(payment_inquiry)

          get :success
        end

        it 'displays an error message' do
          expect(Spree::SolidusSixSaferpay::InquirePaymentPagePayment).to receive(:call).with(payment).and_return(payment_inquiry)
          get :success

          expect(flash[:error]).to eq("payment inquiry message")
        end
      end
    end
  end

  describe 'GET fail' do
    let!(:payment) { create(:six_saferpay_payment, order: order) }
    let(:payment_inquiry) { instance_double("Spree::SolidusSixSaferpay::InquirePaymentPagePayment", user_message: "payment inquiry message") }

    it 'inquires the payment' do
      expect(Spree::SolidusSixSaferpay::InquirePaymentPagePayment).to receive(:call).with(payment).and_return(payment_inquiry)

      get :fail
    end

    it 'displays an error message' do
      expect(Spree::SolidusSixSaferpay::InquirePaymentPagePayment).to receive(:call).with(payment).and_return(payment_inquiry)

      get :fail

      expect(flash[:error]).to eq("payment inquiry message")
    end

  end
end
