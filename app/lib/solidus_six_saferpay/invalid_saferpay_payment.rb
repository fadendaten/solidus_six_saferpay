# frozen_string_literal: true

module SolidusSixSaferpay
  class InvalidSaferpayPayment < StandardError
    def initialize(message: I18n.t(:general_error, scope: [:solidus_six_saferpay, :errors]), details: "")
      super("#{message}: #{details}".strip)
    end

    def full_message
      message
    end
  end
end
