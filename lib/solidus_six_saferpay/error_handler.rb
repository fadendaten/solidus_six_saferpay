# frozen_string_literal: true

module SolidusSixSaferpay
  class ErrorHandler
    # Use a custom error handler so that host applications can configure their
    # error handling
    def self.handle(error, level: :error)
      Rails.logger.send(level, error)

      SolidusSixSaferpay.config.error_handlers.each do |handler|
        if !handler.respond_to?(:call)
          Rails.logger.warn("SolidusSixSaferpay::Configuration ERROR: The attached error handler #{handler} can not be called with #{handler}.call(error, level: level)")

          # skip to next handler
          next
        end
        handler.call(error, level: level)
      end
    end
  end
end
