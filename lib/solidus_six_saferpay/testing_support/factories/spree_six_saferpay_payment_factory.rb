# frozen_string_literal: true

FactoryBot.define do
  factory :six_saferpay_payment, class: 'Spree::SixSaferpayPayment' do
    order
    association :payment_method, factory: :saferpay_payment_method
    expiration { Time.current + 2.hours }
    sequence(:token, (1..100_000).to_a.shuffle.to_enum)

    trait :authorized do
      sequence(:transaction_id) { |n| "TRANSACTION_ID_#{n}" }
      transaction_status { "AUTHORIZED" }
      transaction_date { DateTime.parse("2019-07-25T13:34:44.677+02:00").in_time_zone(Time.zone) }
      sequence(:six_transaction_reference) { |n| "SIX_TRANSACTION_REFERENCE_#{n}" }
      display_text { "xxxx xxxx xxxx 1234" }

      response_hash do
        {
          response_header: {
            request_id: "request-id",
            spec_version: "1.12"
          },
          transaction: {
            type: "PAYMENT",
            status: "AUTHORIZED",
            id: "0QKl2GAnEK0OvA90vClhAESYEGYb",
            date: "2019-07-25T13:34:44.677+02:00",
            amount: {
              value: "20000",
              currency_code: "CHF"
            },
            order_id: "ORDER_ID",
            acquirer_name: "ACQUIRER_NAME",
            acquirer_reference: "ACQUIRER_REFERENCE",
            six_transaction_reference: "SIX_TRANASACTION_REFERENCE",
            approval_code: "APPROVAL CODE"
          },
          payment_means: {
            brand: {
              payment_method: "MASTERCARD",
              name: "MasterCard"
            },
            display_text: "xxxx xxxx xxxx 1234",
            card: {
              masked_number: "xxxxxxxxxxxx1234",
              exp_year: 2019,
              exp_month: 7,
              holder_name: "John Doe",
              country_code: "US"
            }
          },
          payer: {
            ip_address: "IP ADDRESS",
            ip_location: "CH",
            delivery_address: {
              first_name: "Simon",
              last_name: "Knorrli",
              street: "STREET",
              zip: "ZIP",
              city: "CITY",
              country_code: "CH"
            },
            billing_address: {
              first_name: "Simon",
              last_name: "Knorrli",
              street: "STREET",
              zip: "ZIP",
              city: "CITY",
              country_code: "CH"
            }
          },
          liability: {
            liability_shift: true,
            liable_entity: "ThreeDs",
            three_ds: {
              authenticated: true,
              liability_shift: true,
              xid: "3DS-XID"
            }
          }
        }
      end
    end

    trait :without_liability_shift do
      authorized

      after(:build) do |payment|
        payment.response_hash.merge!(
          liability: {
            liability_shift: false,
            liable_entity: "ThreeDs",
            three_ds: {
              authenticated: false,
              liability_shift: false,
              xid: "3DS-XID"
            }
          }
        )
      end
    end

    trait :dcc do
      authorized

      after(:build) do |payment|
        payment.response_hash.merge!(
          dcc: {
            payer_amount: {
              value: "18972",
              currency_code: "USD"
            }
          }
        )
      end
    end
  end
end
