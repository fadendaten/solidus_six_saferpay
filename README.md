# SolidusSixSaferpay

The `solidus_six_saferpay` engine adds checkout options for the Saferpay Payment Page ([Integration Guide](https://saferpay.github.io/sndbx/Integration_PP.html), [JSON API documentation](http://saferpay.github.io/jsonapi/#ChapterPaymentPage)) and the Saferpay Transaction ([Integration Guide](https://saferpay.github.io/sndbx/Integration_trx.html), [JSON API documentation](https://saferpay.github.io/sndbx/Integration_trx.html)).

## Status
Travis CI status: [![Build Status](https://travis-ci.org/fadendaten/solidus_six_saferpay.svg?branch=master)](https://travis-ci.org/fadendaten/solidus_six_saferpay)

## Installation

Add solidus_six_saferpay to your Gemfile:

```ruby
gem 'solidus_six_saferpay'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g solidus_six_saferpay:install
```

Add the following javascript to your `application.js` manifest file below the `//= require spree` line:

```javascript
//= require solidus_six_saferpay/saferpay_payment
```

Configure the credentials for the Saferpay API. These credentials must be set as ENV variables.
You can find the required information in the Saferpay interface under https://test.saferpay.com/BO/Settings/Terminal

```bash
SIX_SAFERPAY_CUSTOMER_ID='XXXXXX'
SIX_SAFERPAY_TERMINAL_ID='XXXXXXXX'
SIX_SAFERPAY_USERNAME='your api basic auth username'
SIX_SAFERPAY_PASSWORD='your api basic auth password'
SIX_SAFERPAY_BASE_URL='https://test.saferpay.com/api/'
SIX_SAFERPAY_CSS_URL='' # currently not tested
```

Configure the host for your application so that we can give Saferpay an absolute URL to redirect on success or failure

```
# in development.rb
Spree::Core::Engine.routes.default_url_options { 'http://localhost:3000' }
```

```
# in production.rb
Spree::Core::Engine.routes.default_url_options { 'https://url-to-your-solidus-shop.tld' }
```

## Configuration and Usage
After adding the `solidus_six_saferpay` gem to your Solidus Rails app, you can create new payment methods `Saferpay Payment Page` and `Saferpay Transaction` in the admin backend under "Settings" > "Payment". When adding a new Saferpay payment method, you can configure the payment method with the information you have received from SIX when creating a new test account.

### Configuration Options

Notable configuration options are:

* `as_iframe`: If checked, the payment form is displayed on the "Payment" checkout page. If unchecked, the user needs to select a payment method and then proceed with the checkout to be redirected to the Saferpay payment interface.
* `require_liability_shift`: If checked, payments are only accepted if Saferpay grants liability shift for the payment. If a payment has no liability shift, then the checkout process fails and the customer needs to use other means of payment.

All other configuration options are restrictions for available payment methods. If you don't check any payment methods, then the interface will make all payment methods available. If you restrict the available payment methods for the user, the interface will reflect your choice. If you select only a single payment method, the user is directly forwarded to the input form for the selected payment method without having to choose themselves.

### Customizing the Confirm Page
If you want to display the masked number on the confirm page, you must override the default `_payment.html.erb` partial of spree so that the provided partial can be rendered (instead of just displaying the name of your payment method).

```erb
<!-- This is the default "app/views/spree/payments/_payment.html.erb" (including our modification) -->
<% source = payment.source %>

<!-- Add this code to render our provided partial that shows the masked number -->
<% if source.is_a?(Spree::SixSaferpayPayment) %>
  <%= render source, payment: payment %>
  
<!-- turn this "if" into an "elsif" to prevent rendering the payment method name -->
<% elsif source.is_a?(Spree::CreditCard) %>
  <span class="cc-type">
    <% unless (cc_type = source.cc_type).blank? %>
      <%= image_tag "credit_cards/icons/#{cc_type}.png" %>
    <% end %>
    <% if source.last_digits %>
      <%= t('spree.ending_in') %> <%= source.last_digits %>
    <% end %>
  </span>
  <br />
  <span class="full-name"><%= source.name %></span>
<% elsif source.is_a?(Spree::StoreCredit) %>
  <%= content_tag(:span, payment.payment_method.name) %>:
  <%= content_tag(:span, payment.display_amount) %>
<% else %>
  <%= content_tag(:span, payment.payment_method.name) %>
<% end %>
```

## Technical Details: How it works

### Overview

This section should provide a birds-eye view of the implementation to help you not get lost when you dive into the details below.

The basic flow for a Saferpay Payment goes like this:

1. User chooses Saferpay payment method on "Payment" checkout step
2. Controller receives AJAX request to initialize Saferpay payment
3. The `InitializePayment` service requests a `token` from the Saferpay API and stores this token in a `SixSaferpayPayment`
4. User enters payment information and submits Saferpay form
5. Controller receives the `success` request from Saferpay
6. Controller asserts/authorizes payment via `AuthorizePayment` service with help of the previously stored `token`
7. If assert/authorize are successful, Controller validates and processes the payment via `ProcessPayment` service which results in a `Spree::Payment`
8. Controller redirects to the "Confirm" checkout step
9. User confirms the purchase
10. During completing the order, `Spree::Payment` initiates the `capture!` of the payment


As you can see, most interactions with the Saferpay API are encapsulated in service objects, which then call the appropriate gateway methods to perform requests.

A note about __error handling__:
If the user aborts the checkout at any point or the payment fails for some other reason, the user is redirected to the "Payment" step of the checkout process and shown an error message.
Additionally, already authorized payments are voided so that no money stays allocated for longer than necessary.

### Technical Implementation Details

In this section, we provide detailed information about the checkout flow and its implementation. Note that the flow is almost identical for both the PaymentPage and the Transaction interface.
Because of this, there is usually a base service class that contains the logic, and then there are subclass services for the PaymentPage and Transaction interface that configure the base service class.

The same pattern also exists for the gateway: The `SolidusSixSaferpay::Gateway` implements the common logic, and the `SolidusSixSaferpay::PaymentPageGateway` and `SolidusSixSaferpay::TransactionGateway` only implement gateway actions that are unique for this interface.

#### Checkout: Payment Initialize
During the "Payment" step of the checkout process, solidus renders a partial for all active and available payment methods. Our partial is called `_saferpay_payment`.
When the partial is loaded, an AJAX request goes to the `CheckoutController#initialize_payment` action.
From there, we make a request to the Saferpay server to initialize the Payment. This request happens via the SixSaferpay Gateway and is abstracted away in the `InitializePayment` service.

If this request is successful, a new `SixSaferpayPayment` object is created. This object contains the Saferpay `Token` for the current payment and links it with the current `Spree::Order` and the used `Spree::PaymentMethod`. It also stores the response of the `PaymentInitialize` request in hash form.

If the initialize request is not successful, then the user is shown an error message.

##### Success
If Saferpay can successfully process the user-submitted information, then Saferpay redirects the user to a `SuccessUrl`, which is configured to be handled by `CheckoutController#success`.
In this `#success` action, we find the `SixSaferpayPayment` record with the correct token that was created in the `PaymentInitialize` request. If the `SixSaferpayPayment` is found, a `PaymentAuthorize` request is performed (abstracted away the `AuthorizePayment` service).

##### Fail
If Saferpay can not successfully process the submitted information or the payment fails for some other reason, Saferpay redirects to a `FailUrl`, which is configured to be handled by `SaferpayPaymentPageController#fail`.
In this `#fail` action, we try to find the `SixSaferpayPayment` record based on the token that was created in the `PaymentPageInitialize` request. If the `SixSaferpayPayment` is found, a `PaymentPageInquire` request is performed to gather information about the failure, and the user is redirected to the "Payment" step of the checkout process and shown an error with information about the failure. If the record can not be found, then a generic error is displayed.

#### Checkout: Payment Authorize
If the user has entered the payment information successfully, we can perform an authorize request. Because this request is different depending on the payment interface, it is explained for each interface below.
When the authorize request is successful, we update the `SixSaferpayPayment` record with the received data. This data most importantly includes:

* `TransactionId`
* `TransactionStatus`
* `TransactionDate`
* `SixTransactionReference`
* `DisplayText`

And, if a credit card was used:

* `MaskedNumber`
* `ExpirationYear`
* `ExpirationMonth`

##### PaymentPage Interface
If the PaymentPage interface is used, then the payment is authorized directly when the user submits the Saferpay form. In this case, we can not perform an authorize request and instead perform an assert request to gather information about the payment.
After performing the assert request, we update the `SixSaferpayPayment` record based on the data from the assert request.

##### Transaction Interface
If the Transaction interface is used, then the payment must be authorized after it has been initialized. Therefore, we perform an authorize request to reserve the requested amount.
If the authorize request is successful, we update the `SixSaferpayPayment` based on the data from the authorize request.


#### Checkout: Payment Validation and Processing
If the authorize request is successful, the received information is validated and processed in the `ProcessPaymentPagePayment` service.
At the moment, the following validations are performed:

* Liability Shift: We check if the liability shift has been granted for the payment
* Payment Status: We check if the payment status of the Saferpay payment is `AUTHORIZED`
* Order Reference: We check if the order referenced by Saferpay matches the order that is being processed
* Matching Amount and Currency: We check if the Saferpay amount and currency match the total and currency of the processed order

If any of these checks fail, then the payment process is aborted and the user must restart the payment flow.

If the payment validation is successful, all previously existing payments for this order that are still valid are cancelled. 
After cancelling old payments, a new `Spree::Payment` is created based on the data stored in the `SixSaferpayPayment` record.
This ensures that only one valid payment exists from this point onward.

If the payment processing fails, then the user is redirected to the "Payment" step of the checkout process and shown an error message.

#### Checkout: Confirm
When the user confirms the purchase in the checkout process, the saferpay payment is automatically captured. This action is triggered in the following way:

1. When the user confirms the order, `Spree::CheckoutController#update` triggers `@order.complete` (through `#transition_forward`)
2. `Spree::Order::Checkout` defines the state transition `before_transition_to :complete, do: :process_payments_before_complete`
3. `Spree::Order` defines `#process_payments_before_complete` and calls `#process_payments!` if any valid payments exist
4. `Spree::Order::Payments` defines `#process_payments!` which calls `process!` on each unprocessed payment
5. `Spree::Payment::Processing` defines `#process!` and calls `#purchase!`
6. `Spree::Payment::Processing` defines `#purchase` and calls `#purchase` on the `PaymentMethod` associated with the payment
7. Since this payment method is a `Spree::PaymentMethod::SaferpayPaymentPage` that inherits from `Spree::PaymentMethod` (through `SaferpayPaymentMethod` and `CreditCard`), the `#purchase` method is delegated to the `#gateway`
8. `Spree::PaymentMethod::SaferpayPaymentPage#gateway_class` defines the gateway to be the `SolidusSixSaferpay::PaymentPageGateway`
9. Therefore, the `PaymentPageGateway#purchase` action is called

#### Checkout: Payment Cancel
When a user cancels a payment, the `CheckoutController` receives a `fail` request and handles this request in the `#fail` action. The result is that the user is shown an error message stating that the payment was aborted.


## Testing

First bundle your dependencies, then run `rake`. `rake` will default to building the dummy app if it does not exist, then it will run specs, and [Rubocop](https://github.com/bbatsov/rubocop) static code analysis. The dummy app can be regenerated by using `rake test_app`.

```shell
bundle
bin/rake
```

When testing your application's integration with this extension you may use its factories.
Simply add this require statement to your spec_helper:

```ruby
require 'solidus_six_saferpay/factories'
```

## Contributing
This gem is available for everyone to use, however chances are that its implementation is still tailored towards our custom solidus-based shop.
If you see improvements to be made, feel free to fork the gem and submit pull requests. All incoming pull requests will be discussed, but it's possible that we will reject pull requests that break functionality for our use case.

## Releasing

Your new extension version can be released using `gem-release` like this:

```shell
bundle exec gem bump -v VERSION --tag --push --remote upstream && gem release
```

Copyright (c) 2020 fadendaten GmbH, released under the New BSD License
