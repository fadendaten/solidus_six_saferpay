# frozen_string_literal: true

FactoryBot.define do
  factory :payment_using_saferpay, class: 'Spree::Payment' do
    association(:payment_method, factory: :saferpay_payment_method)
    source { create(:six_saferpay_payment, :authorized, order: order, payment_method: payment_method) }
    order
    state { 'checkout' }
    response_code { '12345' }
  end
end
