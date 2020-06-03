RSpec.shared_examples 'checkout_controller' do

  routes { Spree::Core::Engine.routes }

  subject { described_class.new }

  let(:user) { create(:user) }
  let(:order) { create(:order) }
  let(:order_number) { order.number }
  let(:payment_method) { create(:saferpay_payment_method_payment_page) }

  before do
    allow(controller).to receive_messages try_spree_current_user: user
    allow(controller).to receive_messages current_order: order
    allow(Spree::Order).to receive(:find_by).with(number: order_number).and_return(order)
  end

  describe 'GET init' do
    let(:success) { false }
    let(:redirect_url) { '/saferpay/redirect/url' }
    let(:initialized_payment) { instance_double("Spree::SolidusSixSaferpay::InitializePayment", success?: success, redirect_url: redirect_url) }

    context 'when the current order for this user is not the one for which payment is initialized' do
      it 'returns an error and redirects to the cart page' do
        allow(Spree::Order).to receive(:find_by).with(number: order_number).and_return(nil)

        get :init, params: { order_number: order_number, payment_method_id: payment_method.id }

        body = JSON.parse(response.body)
        expect(body['errors']).to match(/modified/)
        expect(body['redirect_url']).to eq('/cart')
        expect(response.status).to eq(422)
      end
    end

    it 'tries to initialize the saferpay payment' do
      expect(initialize_payment_service_class).to receive(:call).with(order, payment_method).and_return(initialized_payment)

      get :init, params: { order_number: order_number, payment_method_id: payment_method.id }
    end


    context 'when payment initialize succeeds' do
      let(:success) { true }

      before do
        allow(initialize_payment_service_class).to receive(:call).with(order, payment_method).and_return(initialized_payment)
      end

      it 'returns the redirect_url' do
        get :init, params: { order_number: order_number, payment_method_id: payment_method.id }

        body = JSON.parse(response.body)
        expect(body["redirect_url"]).to eq(redirect_url)
      end
    end

    context 'when payment initialize fails' do
      let(:success) { false }

      before do
        allow(initialize_payment_service_class).to receive(:call).with(order, payment_method).and_return(initialized_payment)
      end


      it 'returns an error and redirects to the cart page' do
        get :init, params: { order_number: order_number, payment_method_id: payment_method.id }

        body = JSON.parse(response.body)
        expect(body['errors']).to match(/could not be initialized/)
        expect(body['redirect_url']).to eq('/cart')
        expect(response.status).to eq(422)
      end
    end

  end


  describe 'GET success' do
    context 'when the order is not found' do
      let(:order) { nil }
      let(:order_number) { "not_found" }

      context 'when a custom error handler exists' do
        let(:handler) { double("handler") }
        let(:error_handler) { Proc.new {|context, order_number| handler.exec(order_number) } }

        before do
          allow(::SolidusSixSaferpay.config).to receive(:payment_processing_order_not_found_handler).and_return(error_handler)
        end

        it 'calls the custom handler' do
          expect(SolidusSixSaferpay.config.payment_processing_order_not_found_handler).to eq(error_handler)
          expect(handler).to receive(:exec).with(order_number)

          get :success, params: { order_number: order_number }
        end
      end

      it 'redirects to the cart page via iframe breakout' do
        get :success, params: { order_number: order_number }
        expect(assigns(:redirect_path)).to eq(routes.cart_path)
        expect(response).to render_template :iframe_breakout_redirect
      end
    end

    context 'when payment could not be created' do
      # We are not creating a payment so there is none to be found in the
      # controller action
      let!(:payment) { nil }

      context 'when a custom error handler exists' do
        let(:handler) { double("handler") }
        let(:error_handler) { Proc.new {|context, order_number| handler.exec(order_number) } }

        before do
          allow(::SolidusSixSaferpay.config).to receive(:payment_processing_payment_not_found_handler).and_return(error_handler)
        end

        it 'calls the custom success processing handler' do
          expect(SolidusSixSaferpay.config.payment_processing_payment_not_found_handler).to eq(error_handler)
          expect(handler).to receive(:exec).with(order)

          get :success, params: { order_number: order_number }
        end
      end

      it 'redirects to the cart page via iframe breakout' do
        get :success, params: { order_number: order_number }
        expect(assigns(:redirect_path)).to eq(routes.cart_path)
        expect(response).to render_template :iframe_breakout_redirect
      end
    end


    context 'when the order is already completed' do
      let(:order) { create(:order_ready_to_ship) }

      it 'redirects to the cart page via iframe breakout' do
        get :success, params: { order_number: order_number }
        expect(assigns(:redirect_path)).to eq(routes.cart_path)
        expect(response).to render_template :iframe_breakout_redirect
      end
    end

    context 'when payment create was successful' do
      let!(:payment) { create(:six_saferpay_payment, order: order) }
      let(:assert_success) { false }
      let(:payment_assert) { instance_double("Spree::SolidusSixSaferpay::AssertPaymentPage", success?: assert_success) }
      let(:payment_inquiry) { instance_double("Spree::SolidusSixSaferpay::InquirePaymentPagePayment", user_message: "payment inquiry message") }

      it 'asserts the payment' do
        expect(authorize_payment_service_class).to receive(:call).with(payment).and_return(payment_assert)
        expect(inquire_payment_service_class).to receive(:call).with(payment).and_return(payment_inquiry)

        get :success, params: { order_number: order_number }
      end

      context 'when the payment assert is successful' do
        let(:assert_success) { true }
        let(:process_success) { false }
        let(:processed_payment) { instance_double("Spree::SolidusSixSaferpay::ProcessPaymentPagePayment", success?: process_success, user_message: "payment processing message") }

        before do
          allow(authorize_payment_service_class).to receive(:call).with(payment).and_return(payment_assert)
        end

        it 'processes the asserted payment' do
          expect(process_authorization_service_class).to receive(:call).with(payment).and_return(processed_payment)

          get :success, params: { order_number: order_number }
        end

        context 'when the processing is successful' do
          let(:process_success) { true }

          before do
            allow(process_authorization_service_class).to receive(:call).with(payment).and_return(processed_payment)
          end

          context 'when a custom success processing handler exists' do
            let(:success_handler) { Proc.new {|context, order| order.touch } }

            before do
              allow(::SolidusSixSaferpay.config).to receive(:payment_processing_success_handler).and_return(success_handler)
            end

            it 'calls the custom success processing handler' do
              expect(SolidusSixSaferpay.config.payment_processing_success_handler).to eq(success_handler)
              expect(order).to receive(:touch)

              get :success, params: { order_number: order_number }
            end
          end


          context 'when order is in payment state' do
            let(:order) { create(:order, state: :payment) }

            it 'moves order to next state' do
              expect(order).to receive(:next!)

              get :success, params: { order_number: order_number }
            end
          end

          context 'when order is already in complete state' do
            let(:order) { create(:order, state: :complete) }

            it 'does not modify the order state' do
              expect(order).not_to receive(:next!)

              get :success, params: { order_number: order_number }
            end
          end
        end

        context 'when the processing fails' do
          let(:process_success) { false }

          before do
            allow(process_authorization_service_class).to receive(:call).with(payment).and_return(processed_payment)
          end

          it 'displays an error message' do
            get :success, params: { order_number: order_number }

            expect(flash[:error]).to eq("payment processing message")
          end
        end

      end

      context 'when the payment assert fails' do
        let(:assert_success) { false }

        before do
          allow(authorize_payment_service_class).to receive(:call).with(payment).and_return(payment_assert)
        end

        it 'inquires the payment' do
          expect(inquire_payment_service_class).to receive(:call).with(payment).and_return(payment_inquiry)

          get :success, params: { order_number: order_number }
        end

        it 'displays an error message' do
          expect(inquire_payment_service_class).to receive(:call).with(payment).and_return(payment_inquiry)
          get :success, params: { order_number: order_number }

          expect(flash[:error]).to eq("payment inquiry message")
        end
      end
    end
  end

  describe 'GET fail' do

    context 'when the order is not found' do
      let(:order) { nil }
      let(:order_number) { "not_found" }

      context 'when a custom error handler exists' do
        let(:handler) { double("handler") }
        let(:error_handler) { Proc.new {|context, order_number| handler.exec(order_number) } }

        before do
          allow(::SolidusSixSaferpay.config).to receive(:payment_processing_order_not_found_handler).and_return(error_handler)
        end

        it 'calls the custom processing handler' do
          expect(SolidusSixSaferpay.config.payment_processing_order_not_found_handler).to eq(error_handler)
          expect(handler).to receive(:exec).with(order_number)

          get :fail, params: { order_number: order_number }
        end
      end

      it 'redirects to the cart page via iframe breakout' do
        get :fail, params: { order_number: order_number }
        expect(assigns(:redirect_path)).to eq(routes.cart_path)
        expect(response).to render_template :iframe_breakout_redirect
      end
    end

    context 'when payment could not be created' do
      # We are not creating a payment so there is none to be found in the
      # controller action
      let!(:payment) { nil }

      context 'when a custom error handler exists' do
        let(:handler) { double("handler") }
        let(:error_handler) { Proc.new {|context, order_number| handler.exec(order_number) } }

        before do
          allow(::SolidusSixSaferpay.config).to receive(:payment_processing_payment_not_found_handler).and_return(error_handler)
        end

        it 'calls the custom success processing handler' do
          expect(SolidusSixSaferpay.config.payment_processing_payment_not_found_handler).to eq(error_handler)
          expect(handler).to receive(:exec).with(order)

          get :fail, params: { order_number: order_number }
        end
      end

      it 'redirects to the cart page via iframe breakout' do
        get :fail, params: { order_number: order_number }
        expect(assigns(:redirect_path)).to eq(routes.cart_path)
        expect(response).to render_template :iframe_breakout_redirect
      end
    end

    context 'when payment create was successful' do
      let!(:payment) { create(:six_saferpay_payment, order: order) }
      let(:payment_inquiry) { instance_double("Spree::SolidusSixSaferpay::InquirePaymentPagePayment", user_message: "payment inquiry message") }

      it 'inquires the payment' do
        expect(inquire_payment_service_class).to receive(:call).with(payment).and_return(payment_inquiry)

        get :fail, params: { order_number: order_number }
      end

      it 'displays an error message' do
        expect(inquire_payment_service_class).to receive(:call).with(payment).and_return(payment_inquiry)

        get :fail, params: { order_number: order_number }

        expect(flash[:error]).to eq("payment inquiry message")
      end

      it 'redirects to the cart page via iframe breakout' do
        expect(inquire_payment_service_class).to receive(:call).with(payment).and_return(payment_inquiry)

        get :fail, params: { order_number: order_number }

        expect(assigns(:redirect_path)).to eq(routes.checkout_state_path(:payment))
        expect(response).to render_template :iframe_breakout_redirect
      end
    end
  end
end
