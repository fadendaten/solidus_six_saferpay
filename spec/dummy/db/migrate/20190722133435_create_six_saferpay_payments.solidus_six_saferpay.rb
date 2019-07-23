# This migration comes from solidus_six_saferpay (originally 20190523075638)
class CreateSixSaferpayPayments < ActiveRecord::Migration[5.1]
  def change
    create_table :spree_six_saferpay_payments do |t|
      t.references :order
      t.references :payment_method

      t.string :token
      t.datetime :expiration
      t.string :redirect_url
      t.string :transaction_id
      t.string :transaction_status
      t.datetime :transaction_date
      t.string :six_transaction_reference
      t.string :display_text
      t.string :masked_number
      t.string :expiration_year
      t.string :expiration_month
      t.text :response_hash

      t.timestamps
    end

    add_index :spree_six_saferpay_payments, :token, unique: true
    add_index :spree_six_saferpay_payments, :transaction_id, unique: true
    add_index :spree_six_saferpay_payments, :six_transaction_reference, unique: true

    # hack around foreign_key restriction by manually defining them
    add_foreign_key :spree_six_saferpay_payments, :spree_orders, column: :order_id
    add_foreign_key :spree_six_saferpay_payments, :spree_payment_methods, column: :payment_method_id
  end
end
