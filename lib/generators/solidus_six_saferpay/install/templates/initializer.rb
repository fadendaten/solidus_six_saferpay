# frozen_string_literal: true

SolidusSixSaferpay.configure do |config|
  # example error handler for Rollbar
  # config.error_handlers << Proc.new { |error, options| Rollbar.send(options[:level], error) }
  #
  config.error_handlers = []
end
