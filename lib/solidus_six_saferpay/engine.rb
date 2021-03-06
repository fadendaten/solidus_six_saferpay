# frozen_string_literal: true

require 'spree/core'
module SolidusSixSaferpay

  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield config
  end

  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions::Decorators

    isolate_namespace ::Spree

    engine_name 'solidus_six_saferpay'

    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.eager_load_paths += Dir["#{config.root}/lib/**/"]

    initializer "spree.six_payment.payment_methods", :after => "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << Spree::PaymentMethod::SaferpayPaymentPage
      app.config.spree.payment_methods << Spree::PaymentMethod::SaferpayTransaction
    end

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
