# frozen_string_literal: true

if Rails.application.config.respond_to?(:assets)
  Rails.application.config.assets.precompile << 'solidus_six_saferpay_manifest.js'
end
