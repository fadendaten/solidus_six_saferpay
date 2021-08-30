# frozen_string_literal: true

module SolidusSixSaferpay
  class PaymentPageGateway < Gateway
    def inquire(saferpay_payment, options = {})
      inquire_response = perform_assert_request(saferpay_payment, options)

      response(
        true,
        "Saferpay Payment Page inquire (assert) response: #{inquire_response.to_h}",
        inquire_response
      )
    rescue SixSaferpay::Error => e
      handle_error(e, inquire_response)
    end

    # NOTE: Since PaymentPage payments are automatically authorized,
    # the passed amount has no effect because the payment is automatically
    # authorized for the full amount
    def authorize(_amount, saferpay_payment, options = {})
      assert(saferpay_payment, options)
    end

    def assert(saferpay_payment, options = {})
      assert_response = perform_assert_request(saferpay_payment, options)

      response(
        true,
        "Saferpay Payment Page assert response: #{assert_response.to_h}",
        assert_response
      )
    rescue SixSaferpay::Error => e
      handle_error(e, assert_response)
    end

    private

    def return_urls(order)
      SixSaferpay::ReturnUrls.new(
        success: url_helpers.solidus_six_saferpay_payment_page_success_url(order.number),
        fd_fail: url_helpers.solidus_six_saferpay_payment_page_fail_url(order.number),
        fd_abort: url_helpers.solidus_six_saferpay_payment_page_fail_url(order.number)
      )
    end

    def perform_assert_request(saferpay_payment, _options = {})
      payment_page_assert = SixSaferpay::SixPaymentPage::Assert.new(token: saferpay_payment.token)
      SixSaferpay::Client.post(payment_page_assert)
    end

    def interface_initialize_class
      SixSaferpay::SixPaymentPage::Initialize
    end
  end
end
