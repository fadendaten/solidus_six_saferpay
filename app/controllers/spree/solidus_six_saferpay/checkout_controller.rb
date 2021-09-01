# frozen_string_literal: true

module Spree
  module SolidusSixSaferpay
    class CheckoutController < StoreController
      def init
        order_number = params[:order_number]
        @order = Spree::Order.find_by(number: order_number)

        # We must make sure that the order for which the user requests a
        # payment is still their `current_order`.
        # This can be false if the user tries to add something to the cart
        # after getting to the payment checkout step, and then switches back to
        # the payment step and starts the payment process by selecting a
        # payment method.
        # In that case, we redirect to the checkout path so the user needs to
        # go through the checkout process again to ensure that the real
        # `current_order` contains all necessary information.
        if @order.nil? || @order != current_order
          render json: {
            redirect_url: spree.cart_path,
            errors: t('.order_was_modified_after_confirmation')
          }, status: :unprocessable_entity
          return
        end

        payment_method = Spree::PaymentMethod.find(params[:payment_method_id])
        initialized_payment = initialize_payment(@order, payment_method)

        if initialized_payment.success?
          redirect_url = initialized_payment.redirect_url
          render json: { redirect_url: redirect_url }
        else
          render json: {
            redirect_url: spree.cart_path,
            errors: t('.checkout_not_initialized')
          }, status: :unprocessable_entity
        end
      end

      def success
        order_number = params[:order_number]
        @order = Spree::Order.find_by(number: order_number)

        if @order.nil?
          OrderNotFoundHandler.call(controller_context: self, order_number: order_number)

          flash[:error] = t('.error_while_processing_payment')
          @redirect_path ||= spree.cart_path

          render :iframe_breakout_redirect, layout: false
          return
        end

        # ensure that completed orders don't try to reprocess the
        # authorization. This could happen if a user presses the back button
        # after completing an order.
        # There is no error handling because it should look like you are simply
        # redirected to the cart page.
        if @order.completed?
          @redirect_path = spree.cart_path
          render :iframe_breakout_redirect, layout: false
          return
        end

        saferpay_payment = Spree::SixSaferpayPayment.current_payment(order)

        if saferpay_payment.nil?
          PaymentNotFoundHandler.call(controller_context: self, order: @order)

          flash[:error] = t('.error_while_processing_payment')
          @redirect_path ||= spree.cart_path

          render :iframe_breakout_redirect, layout: false
          return
        end

        # NOTE: PaymentPage payments are authorized directly. Instead, we
        # perform an ASSERT here to gather the necessary details.
        # This might be confusing at first, but doing it this way makes sense
        # (and the code a LOT more readable) IMO. Feel free to disagree and PR
        # a better solution.
        # NOTE: Transaction payments are authorized here so that the money is
        # already allocated when the user is on the confirm page. If the user
        # then chooses another payment, the authorized payment is voided
        # (cancelled).
        payment_authorization = authorize_payment(saferpay_payment)

        if payment_authorization.success?

          processed_authorization = process_authorization(saferpay_payment)
          if processed_authorization.success?
            PaymentProcessingSuccessHandler.call(controller_context: self, order: @order)
          else
            flash[:error] = processed_authorization.user_message
          end

        else
          payment_inquiry = inquire_payment(saferpay_payment)
          flash[:error] = payment_inquiry.user_message
        end

        @redirect_path ||= order_checkout_path(@order.state)
        render :iframe_breakout_redirect, layout: false
      end

      def fail
        order_number = params[:order_number]
        @order = Spree::Order.find_by(number: order_number)

        if @order.nil?
          OrderNotFoundHandler.call(controller_context: self, order_number: order_number)

          flash[:error] = t('.error_while_processing_payment')
          @redirect_path ||= spree.cart_path

          render :iframe_breakout_redirect, layout: false
          return
        end

        saferpay_payment = Spree::SixSaferpayPayment.where(order_id: @order.id).order(:created_at).last

        if saferpay_payment.nil?
          PaymentNotFoundHandler.call(controller_context: self, order: @order)

          flash[:error] = t('.error_while_processing_payment')
          @redirect_path = spree.cart_path
          render :iframe_breakout_redirect, layout: false
          return
        end

        payment_inquiry = inquire_payment(saferpay_payment)
        flash[:error] = payment_inquiry.user_message

        @redirect_path = order_checkout_path(:payment)
        render :iframe_breakout_redirect, layout: false
      end

      private

      def initialize_payment(_order, _payment_method)
        raise NotImplementedError,
          "Must be implemented in PaymentPageCheckoutController or TransactionCheckoutController"
      end

      def authorize_payment(_saferpay_payment)
        raise NotImplementedError,
          "Must be implemented in PaymentPageCheckoutController or TransactionCheckoutController"
      end

      def process_authorization(_saferpay_payment)
        raise NotImplementedError,
          "Must be implemented in PaymentPageCheckoutController or TransactionCheckoutController"
      end

      def inquire_payment(_saferpay_payment)
        raise NotImplementedError,
          "Must be implemented in PaymentPageCheckoutController or TransactionCheckoutController"
      end

      def order_checkout_path(state)
        Spree::Core::Engine.routes.url_helpers.checkout_state_path(state)
      end
    end
  end
end
