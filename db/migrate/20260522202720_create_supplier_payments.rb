class CreateSupplierPayments < ActiveRecord::Migration[7.1]
  def change
    create_table :supplier_payments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.references :purchase, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :amount
      t.string :payment_method
      t.string :reference_number
      t.date :paid_on
      t.text :notes

      t.timestamps
    end
  end
end
