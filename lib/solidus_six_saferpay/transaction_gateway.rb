# frozen_string_literal: true

module SolidusSixSaferpay
  class TransactionGateway < Gateway
    def inquire(saferpay_payment, _options = {})
      transaction_inquire =
        SixSaferpay::SixTransaction::Inquire.new(transaction_reference:
                                                 saferpay_payment.transaction_id)
      inquire_response = SixSaferpay::Client.post(transaction_inquire)

      response(
        true,
        "Saferpay Transaction inquire response: #{inquire_response.to_h}",
        inquire_response
      )
    rescue SixSaferpay::Error => e
      handle_error(e, inquire_response)
    end

    # NOTE: Saferpay does not allow authorization for partial amounts.
    # Therefore, the given amount is ignored
    def authorize(_amount, saferpay_payment, _options = {})
      transaction_authorize = SixSaferpay::SixTransaction::Authorize.new(token: saferpay_payment.token)
      authorize_response = SixSaferpay::Client.post(transaction_authorize)

      response(
        true,
        "Saferpay Transaction authorize response: #{authorize_response.to_h}",
        authorize_response
      )
    rescue SixSaferpay::Error => e
      handle_error(e, authorize_response)
    end

    private

    def interface_initialize_object(order, payment_method)
      SixSaferpay::SixTransaction::Initialize.new(interface_initialize_params(order, payment_method))
    end

    def return_urls(order)
      SixSaferpay::ReturnUrls.new(
        success: url_helpers.solidus_six_saferpay_transaction_success_url(order.number),
        fd_fail: url_helpers.solidus_six_saferpay_transaction_fail_url(order.number),
        fd_abort: url_helpers.solidus_six_saferpay_transaction_fail_url(order.number)
      )
    end
  end
end
