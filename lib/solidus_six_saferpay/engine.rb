# frozen_string_literal: true

require 'solidus_core'
require 'solidus_support'

require 'six_saferpay'

module SolidusSixSaferpay
  class Engine < Rails::Engine
    engine_name 'solidus_six_saferpay'

    include SolidusSupport::EngineExtensions

    isolate_namespace ::Spree

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

    # remove original activate method
    def self.activate
      Dir.glob(File.join(root, "app/**/*_decorator*.rb")).sort.each do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare(&method(:activate).to_proc)
  end
end
