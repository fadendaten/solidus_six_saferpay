# frozen_string_literal: true

require 'solidus_core'
require 'solidus_support'

require 'six_saferpay'

module SolidusSixSaferpay
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace ::Spree

    engine_name 'solidus_six_saferpay'

    config.autoload_paths << "#{config.root}/lib"

    # config.autoload_paths += Dir["#{config.root}/lib/**/"]
    # config.eager_load_paths += Dir["#{config.root}/lib/**/"]

    initializer "spree.six_payment.payment_methods", after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << Spree::PaymentMethod::SaferpayPaymentPage
      app.config.spree.payment_methods << Spree::PaymentMethod::SaferpayTransaction
    end

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
