module Spree
  module SolidusSixSaferpay
    class CheckoutController < StoreController

      def init
        @order = current_order
        redirect_to(spree.cart_path) && return unless @order


        payment_method = Spree::PaymentMethod.find(params[:payment_method_id])
        Spree::LogEntry.create(
          source: @order,
          details: "Initializing Spree::SixSaferpayPayment for PaymentMethod #{payment_method.id} (#{payment_method.name})"
        )
        initialized_payment = initialize_payment(@order, payment_method)

        if initialized_payment.success?
          redirect_url = initialized_payment.redirect_url
          render json: { redirect_url: redirect_url }
        else
          render json: { errors: t('.checkout_not_initialized') }, status: 422
        end
      end

      def success
        order_number = params[:order_number]
        @order = Spree::Order.find_by(number: order_number)

        Spree::LogEntry.create(
          source: @order,
          details: "A payment for this order was completed successfully by the user. We are now trying to handle this payment."
        )

        if @order.nil?
          @redirect_path = spree.cart_path
          render :iframe_breakout_redirect, layout: false
          return
        end

        # ensure that completed orders don't try to reprocess the
        # authorization. This could happen if a user presses the back button
        # after completing an order.
        if @order.completed?
          Spree::LogEntry.create(
            source: @order,
            details: "Order already completed. Redirecting to cart path."
          )
          @redirect_path = spree.cart_path
          render :iframe_breakout_redirect, layout: false
          return
        end

        saferpay_payment = Spree::SixSaferpayPayment.where(order_id: @order.id).order(:created_at).last

        if saferpay_payment.nil?
          Spree::LogEntry.create(
            source: @order,
            details: "Could not find a Spree::SixSaferpayPayment for this order."
          )
          raise Spree::Core::GatewayError, t('.saferpay_payment_not_found')
        end

        Spree::LogEntry.create(
          source: @order,
          details: "The payment #{saferpay_payment.id} is being authorized and then processed."
        )

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
            Spree::LogEntry.create(
              source: @order,
              details: "The Spree::SixSaferpayPayment #{saferpay_payment.id} was processed successfully. Now handling processing success."
            )
            handle_payment_processing_success
          else
            Spree::LogEntry.create(
              source: @order,
              details: "The Spree::SixSaferpayPayment #{saferpay_payment.id} failed to process. User was informed with: #{processed_authorization.user_message}"
            )
            flash[:error] = processed_authorization.user_message
          end

        else
          payment_inquiry = inquire_payment(saferpay_payment)
          Spree::LogEntry.create(
            source: @order,
            details: "The Spree::SixSaferpayPayment #{saferpay_payment.id} could not be authorized. User was informed with: #{payment_inquiry.user_message}"
          )
          flash[:error] = payment_inquiry.user_message
        end

        @redirect_path ||= order_checkout_path(@order.state)
        render :iframe_breakout_redirect, layout: false
      end

      def fail
        order_number = params[:order_number]
        @order = Spree::Order.find_by(number: order_number)

        if @order.nil?
          @redirect_path = spree.cart_path
          render :iframe_breakout_redirect, layout: false
          return
        end

        saferpay_payment = Spree::SixSaferpayPayment.where(order_id: @order.id).order(:created_at).last


        if saferpay_payment
          payment_inquiry = inquire_payment(saferpay_payment)
          Spree::LogEntry.create(
            source: @order,
            details: "FAIL: The Spree::SixSaferpayPayment #{saferpay_payment.id} failed. User was informed with: #{user_message}"
          )
          flash[:error] = payment_inquiry.user_message
        else
          user_message = I18n.t(:general_error, scope: [:solidus_six_saferpay, :errors])
          Spree::LogEntry.create(
            source: @order,
            details: "FAIL: A payment for this order failed, but we can not find it. User was informed with #{user_message}",
          )
          flash[:error] = user_message
        end

        @redirect_path = order_checkout_path(:payment)
        render :iframe_breakout_redirect, layout: false
      end

      private

      def initialize_payment(order, payment_method)
        raise NotImplementedError, "Must be implemented in PaymentPageCheckoutController or TransactionCheckoutController"
      end

      def authorize_payment(saferpay_payment)
        raise NotImplementedError, "Must be implemented in PaymentPageCheckoutController or TransactionCheckoutController"
      end

      def process_authorization(saferpay_payment)
        raise NotImplementedError, "Must be implemented in PaymentPageCheckoutController or TransactionCheckoutController"
      end

      def inquire_payment(saferpay_payment)
        raise NotImplementedError, "Must be implemented in PaymentPageCheckoutController or TransactionCheckoutController"
      end

      # Allows overriding of success behaviour in host application by setting
      # SolidusSixSaferpay.config.payment_processing_success_handler
      # 
      # By default, it will ensure that the order state is no longer "payment"
      #
      # Example
      # config.payment_processing_success_handler = Proc.new { |order| puts "Order #{order} has been successfully paid!" }
      #
      def handle_payment_processing_success
        if success_handler = ::SolidusSixSaferpay.config.payment_processing_success_handler.presence
          success_handler.call(self, @order)
        else
          @order.next! if @order.payment?
        end
      end

      def order_checkout_path(state)
        Spree::Core::Engine.routes.url_helpers.checkout_state_path(state)
      end
    end
  end
end
