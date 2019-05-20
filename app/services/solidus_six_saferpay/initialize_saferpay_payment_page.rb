module SolidusSixSaferpay

  # TODO: SPEC
  class InitializeSaferpayPaymentPage

    attr_reader :order, :token, :redirect_url, :success

    def self.call(order)
      new(order).call
    end

    def initialize(order)
      @order = order
    end

    def call
      payment_page_initialize = ActiveMerchant::Billing::Gateways::SixSaferpayPaymentPageGateway.new.initialize_payment_page(order)

      if payment_page_initialize.success?
        @success = payment_page_initialize.success?
        @token = payment_page_initialize.params[:Token]
        @redirect_url = payment_page_initialize.params[:RedirectUrl]
        SaferpayPayment.create!(order: order, token: token)
      else
        raise "PaymentPageInitialize not successful"
      end
      self
    end

    def success?
      @success
    end
  end
end
