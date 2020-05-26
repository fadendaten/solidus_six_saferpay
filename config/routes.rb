# frozen_string_literal: true

Spree::Core::Engine.routes.draw do
  namespace :solidus_six_saferpay do
    namespace :payment_page do
      get :init, controller: :checkout, defaults: { format: :json }
      get 'success/:order_number', to: 'checkout#success', as: :success
      get 'fail/:order_number', to: 'checkout#fail', as: :fail
    end

    namespace :transaction do
      get :init, controller: :checkout, defaults: { format: :json }
      get 'success/:order_number', to: 'checkout#success', as: :success
      get 'fail/:order_number', to: 'checkout#fail', as: :fail
    end
  end
end
