Spree::Core::Engine.routes.draw do

  namespace :solidus_six_saferpay do
    scope :payment_page do
      get 'init', controller: 'saferpay_payment_page', defaults: { format: :json }, as: :payment_page_init
      get 'success', controller: 'saferpay_payment_page', as: :payment_page_success
      get 'fail', controller: 'saferpay_payment_page', as: :payment_page_fail
      get 'cancel', controller: 'saferpay_payment_page', as: :payment_page_cancel
    end
  end

end
