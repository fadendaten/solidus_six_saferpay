# frozen_string_literal: true

module SolidusSixSaferpay
  class ErrorHandler
    # Use a custom error handler so that host applications can configure their
    # error handling
    def self.handle(error, level: :error)
      Rails.logger.send(level, error)

      SolidusSixSaferpay.config.error_handlers.each do |handler|
        begin
          handler.call(error, level: level)
        rescue StandardError
          Rails.logger.warn("SolidusSixSaferpay::Configuration ERROR: The" \
                            "attached error handler #{handler} can not be called" \
                            "with #{handler}.call(error, level: level)")
          next
        end
      end
    end
  end
end
