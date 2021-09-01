# frozen_string_literal: true

FactoryBot.define do
  factory :saferpay_payment_method, class: 'Spree::PaymentMethod::SaferpayPaymentMethod' do
    name  { "saferpay_payment_method" }
    preferred_require_liability_shift { true }

    trait :no_require_liability_shift do
      preferred_require_liability_shift { false }
    end

    trait :no_as_iframe do
      preferred_as_iframe { false }
    end
  end

  factory :saferpay_payment_method_payment_page, class: 'Spree::PaymentMethod::SaferpayPaymentPage',
parent: :saferpay_payment_method do
    name { "saferpay_payment_page" }
  end

  factory :saferpay_payment_method_transaction, class: 'Spree::PaymentMethod::SaferpayTransaction',
parent: :saferpay_payment_method do
    name { "saferpay_transaction" }
  end
end
