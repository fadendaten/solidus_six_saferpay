# frozen_string_literal: true

Spree::Core::Engine.routes.draw do
  namespace :solidus_six_saferpay do
    namespace :payment_page do
      get :init, controller: :checkout, defaults: { format: :json }
      get :success, controller: :checkout
      get :fail, controller: :checkout
    end

    namespace :transaction do
      get :init, controller: :checkout, defaults: { format: :json }
      get :success, controller: :checkout
      get :fail, controller: :checkout
    end
  end
end
