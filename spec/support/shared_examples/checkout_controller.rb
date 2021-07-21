RSpec.shared_examples 'checkout_controller' do
  routes { Spree::Core::Engine.routes }

  subject { described_class.new }

  let(:payment_method) { create(:saferpay_payment_method_payment_page) }

  before do
    allow(controller).to receive_messages try_spree_current_user: instance_double('Spree::User')
  end

  describe 'GET init' do
    context 'when the current order for this user is not the one for which payment is initialized' do
      before do
        allow(Spree::Order).to receive(:find_by).and_return(nil)
      end

      it 'returns an error code' do
        get :init, params: { order_number: '12345', payment_method_id: payment_method.id }

        expect(response.status).to eq(422)
      end

      it 'returns an error message' do
        get :init, params: { order_number: '12345', payment_method_id: payment_method.id }

        body = JSON.parse(response.body)
        expect(body['errors']).to match(/modified/)
      end

      it 'redirects to the cart page' do
        get :init, params: { order_number: '12345', payment_method_id: payment_method.id }

        body = JSON.parse(response.body)
        expect(body['redirect_url']).to eq('/cart')
      end
    end

    context 'when the order is found' do
      let(:order) { create(:order) }
      let(:initialized_payment) {
        instance_double(
          "Spree::SolidusSixSaferpay::InitializePayment",
          success?: false,
          redirect_url: '/saferpay/redirect/url'
        )
      }

      before do
        allow(controller).to receive_messages current_order: order
        allow(Spree::Order).to receive(:find_by).with(number: order.number).and_return(order)
      end

      it 'tries to initialize the saferpay payment' do
        allow(initialize_payment_service_class).to receive(:call).with(
          order,
          payment_method
        ).and_return(initialized_payment)

        get :init, params: { order_number: order.number, payment_method_id: payment_method.id }

        expect(initialize_payment_service_class).to have_received(:call)
      end

      context 'when payment initialize succeeds' do
        let(:initialized_payment) {
          instance_double(
            "Spree::SolidusSixSaferpay::InitializePayment",
            success?: true,
            redirect_url: '/saferpay/redirect/url'
          )
        }

        before do
          allow(initialize_payment_service_class).to receive(:call).with(
            order,
            payment_method
          ).and_return(initialized_payment)
        end

        it 'returns the redirect_url' do
          get :init, params: { order_number: order.number, payment_method_id: payment_method.id }

          body = JSON.parse(response.body)
          expect(body["redirect_url"]).to eq('/saferpay/redirect/url')
        end
      end

      context 'when payment initialize fails' do
        let(:initialized_payment) {
          instance_double(
            "Spree::SolidusSixSaferpay::InitializePayment",
            success?: false,
            redirect_url: '/saferpay/redirect/url'
          )
        }

        before do
          allow(initialize_payment_service_class).to receive(:call).with(
            order,
            payment_method
          ).and_return(initialized_payment)
        end

        it 'returns an error code' do
          get :init, params: { order_number: order.number, payment_method_id: payment_method.id }

          expect(response.status).to eq(422)
        end

        it 'returns an error message' do
          get :init, params: { order_number: order.number, payment_method_id: payment_method.id }

          body = JSON.parse(response.body)
          expect(body['errors']).to match(/could not be initialized/)
        end

        it 'redirects to the cart page' do
          get :init, params: { order_number: order.number, payment_method_id: payment_method.id }

          body = JSON.parse(response.body)
          expect(body['redirect_url']).to eq('/cart')
        end
      end
    end
  end

  describe 'GET success' do
    let(:order_number) { '12345' }

    context 'when the order is not found' do
      before do
        allow(Spree::Order).to receive(:find_by).with(number: order_number).and_return(nil)
      end

      it 'calls the relevant handler service' do
        allow(Spree::SolidusSixSaferpay::OrderNotFoundHandler).to receive(:call).with(
          controller_context: @controller, # rubocop:disable RSpec/InstanceVariable
          order_number: order_number
        )

        get :success, params: { order_number: order_number }

        expect(Spree::SolidusSixSaferpay::OrderNotFoundHandler).to have_received(:call)
      end

      it 'renders the iframe breakout' do
        get :success, params: { order_number: order_number }
        expect(response).to render_template :iframe_breakout_redirect
      end

      it 'redirects to the cart page' do
        get :success, params: { order_number: order_number }
        expect(assigns(:redirect_path)).to eq(routes.cart_path)
      end
    end

    context 'when the order is found' do
      let(:order) { create(:order, number: order_number) }

      before do
        allow(Spree::Order).to receive(:find_by).with(number: order_number).and_return(order)
      end

      context 'when the order is already completed' do
        let(:order) { create(:order_ready_to_ship, number: order_number) }

        it 'renders the iframe breakout' do
          get :success, params: { order_number: order_number }
          expect(response).to render_template :iframe_breakout_redirect
        end

        it 'redirects to the cart page' do
          get :success, params: { order_number: order_number }
          expect(assigns(:redirect_path)).to eq(routes.cart_path)
        end
      end
    end

    context 'when no payment is found for this order' do
      let(:order) { create(:order, number: order_number) }

      before do
        allow(Spree::Order).to receive(:find_by).with(number: order_number).and_return(order)
      end

      it 'calls the relevant handler service' do
        allow(Spree::SolidusSixSaferpay::PaymentNotFoundHandler).to receive(:call).with(
          controller_context: @controller, # rubocop:disable RSpec/InstanceVariable
          order: order
        )
        get :success, params: { order_number: order_number }

        expect(Spree::SolidusSixSaferpay::PaymentNotFoundHandler).to have_received(:call)
      end

      it 'renders the iframe breakout' do
        get :success, params: { order_number: order_number }
        expect(response).to render_template :iframe_breakout_redirect
      end

      it 'redirects to the cart page' do
        get :success, params: { order_number: order_number }
        expect(assigns(:redirect_path)).to eq(routes.cart_path)
      end
    end

    context 'when a saferpay payment is found' do
      let(:order) { create(:order, number: order_number) }
      let(:payment) { create(:six_saferpay_payment, order: order) }

      let(:payment_assert) {
        instance_double(
          'Spree::SolidusSixSaferpay::AuthorizePayment',
          success?: false
        )
      }

      before do
        allow(authorize_payment_service_class).to receive(:call).with(payment).and_return(payment_assert)

        # inquire will be called because our assert fails, that's why we need to stub it already
        allow(inquire_payment_service_class).to receive(:call).with(payment).and_return(
          instance_double('Spree::SolidusSixSaferpay::InquirePayment', user_message: 'payment inquiry message')
        )
      end

      it 'asserts the payment' do
        get :success, params: { order_number: order_number }

        expect(authorize_payment_service_class).to have_received(:call)
      end

      context 'when assert fails' do
        it 'inquires the payment to fetch details' do
          get :success, params: { order_number: order_number }

          expect(inquire_payment_service_class).to have_received(:call)
        end

        it 'displays an error message' do
          get :success, params: { order_number: order_number }

          expect(flash[:error]).to eq("payment inquiry message")
        end
      end
    end

    context 'when assert succeeds' do
      let(:payment) { create(:six_saferpay_payment, order: create(:order, number: order_number)) }
      let(:payment_assert) {
        instance_double(
          'Spree::SolidusSixSaferpay::AuthorizePayment',
          success?: true
        )
      }
      let(:processed_payment) {
        instance_double(
          "Spree::SolidusSixSaferpay::ProcessPaymentPagePayment",
          success?: false,
          user_message: 'payment processing message'
        )
      }

      before do
        allow(authorize_payment_service_class).to receive(:call).with(payment).and_return(payment_assert)
        allow(process_authorization_service_class).to receive(:call).with(payment).and_return(processed_payment)
      end

      it 'processes the asserted payment' do
        get :success, params: { order_number: order_number }

        expect(process_authorization_service_class).to have_received(:call)
      end
    end

    context 'when the processing is successful' do
      let(:payment) { create(:six_saferpay_payment, order: create(:order, number: order_number)) }
      let(:payment_assert) {
        instance_double(
          'Spree::SolidusSixSaferpay::AuthorizePayment',
          success?: true
        )
      }
      let(:processed_payment) {
        instance_double(
          "Spree::SolidusSixSaferpay::ProcessPaymentPagePayment",
          success?: true,
          user_message: "payment processing message"
        )
      }

      before do
        allow(Spree::Order).to receive(:find_by).with(number: order_number).and_return(payment.order)
        allow(authorize_payment_service_class).to receive(:call).with(payment).and_return(payment_assert)
        allow(process_authorization_service_class).to receive(:call).with(payment).and_return(processed_payment)
      end

      it 'calls the custom success processing handler' do
        allow(Spree::SolidusSixSaferpay::PaymentProcessingSuccessHandler).to receive(:call).with(
          controller_context: @controller, # rubocop:disable RSpec/InstanceVariable
          order: payment.order
        ).and_return(true)

        get :success, params: { order_number: order_number }

        expect(Spree::SolidusSixSaferpay::PaymentProcessingSuccessHandler).to have_received(:call).with(
          controller_context: @controller, # rubocop:disable RSpec/InstanceVariable
          order: payment.order
        )
      end

      context 'when order is in payment state' do
        let(:payment) { create(:six_saferpay_payment, order: create(:order, number: order_number, state: :payment)) }

        it 'moves order to next state' do
          allow(payment.order).to receive(:next!)
          get :success, params: { order_number: order_number }

          expect(payment.order).to have_received(:next!)
        end
      end

      context 'when order is already in complete state' do
        let(:payment) { create(:six_saferpay_payment, order: create(:order_ready_to_ship, number: order_number)) }

        it 'does not modify the order state' do
          allow(payment.order).to receive(:next!)
          get :success, params: { order_number: order_number }

          expect(payment.order).not_to have_received(:next!)
        end
      end
    end

    context 'when the processing fails' do
      let(:payment) { create(:six_saferpay_payment, order: create(:order, number: order_number)) }
      let(:payment_assert) {
        instance_double(
          'Spree::SolidusSixSaferpay::AuthorizePayment',
          success?: true
        )
      }
      let(:processed_payment) {
        instance_double(
          "Spree::SolidusSixSaferpay::ProcessPaymentPagePayment",
          success?: false,
          user_message: "payment processing message"
        )
      }

      before do
        allow(authorize_payment_service_class).to receive(:call).with(payment).and_return(payment_assert)
        allow(process_authorization_service_class).to receive(:call).with(payment).and_return(processed_payment)
        allow(inquire_payment_service_class).to receive(:call).with(payment).and_return(
          instance_double('Spree::SolidusSixSaferpay::InquirePayment', user_message: 'payment inquiry message')
        )
      end

      it 'displays an error message' do
        get :success, params: { order_number: order_number }

        expect(flash[:error]).to eq("payment processing message")
      end
    end
  end

  describe 'GET fail' do
    let(:order_number) { '12345' }

    context 'when the order is not found' do
      before do
        allow(Spree::Order).to receive(:find_by).with(number: order_number).and_return(nil)
      end

      it 'calls the relevant handler service' do
        allow(Spree::SolidusSixSaferpay::OrderNotFoundHandler).to receive(:call).with(
          controller_context: @controller, # rubocop:disable RSpec/InstanceVariable
          order_number: order_number
        )
        get :fail, params: { order_number: order_number }

        expect(Spree::SolidusSixSaferpay::OrderNotFoundHandler).to have_received(:call)
      end

      it 'renders the iframe breakout' do
        get :fail, params: { order_number: order_number }
        expect(response).to render_template :iframe_breakout_redirect
      end

      it 'redirects to the cart page' do
        get :fail, params: { order_number: order_number }
        expect(assigns(:redirect_path)).to eq(routes.cart_path)
      end
    end

    context 'when the order is found' do
      let(:order) { create(:order, number: order_number) }

      before do
        allow(Spree::Order).to receive(:find_by).with(number: order_number).and_return(order)
      end

      context 'when no payment is found for this order' do
        it 'calls the relevant handler service' do
          allow(Spree::SolidusSixSaferpay::PaymentNotFoundHandler).to receive(:call).with(
            controller_context: @controller, # rubocop:disable RSpec/InstanceVariable
            order: order
          )

          get :fail, params: { order_number: order_number }

          expect(Spree::SolidusSixSaferpay::PaymentNotFoundHandler).to have_received(:call)
        end

        it 'renders the iframe breakout' do
          get :fail, params: { order_number: order_number }

          expect(response).to render_template :iframe_breakout_redirect
        end

        it 'redirects to the cart page' do
          get :fail, params: { order_number: order_number }

          expect(assigns(:redirect_path)).to eq(routes.cart_path)
        end
      end

      context 'when payment create was successful' do
        let!(:payment) { create(:six_saferpay_payment, order: order) }
        let(:payment_inquiry) {
          instance_double(
            "Spree::SolidusSixSaferpay::InquirePaymentPagePayment",
            user_message: "payment inquiry message"
          )
        }

        it 'inquires the payment' do
          allow(inquire_payment_service_class).to receive(:call).with(payment).and_return(payment_inquiry)

          get :fail, params: { order_number: order_number }
          expect(inquire_payment_service_class).to have_received(:call)
        end

        it 'displays an error message' do
          allow(inquire_payment_service_class).to receive(:call).with(payment).and_return(payment_inquiry)

          get :fail, params: { order_number: order_number }

          expect(flash[:error]).to eq("payment inquiry message")
        end

        it 'renders the iframe breakout' do
          allow(inquire_payment_service_class).to receive(:call).with(payment).and_return(payment_inquiry)

          get :fail, params: { order_number: order_number }

          expect(response).to render_template :iframe_breakout_redirect
        end

        it 'redirects to the payment checkout step' do
          allow(inquire_payment_service_class).to receive(:call).with(payment).and_return(payment_inquiry)

          get :fail, params: { order_number: order_number }

          expect(assigns(:redirect_path)).to eq(routes.checkout_state_path(:payment))
        end
      end
    end
  end
end
