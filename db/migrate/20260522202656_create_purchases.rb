class CreatePurchases < ActiveRecord::Migration[7.1]
  def change
    create_table :purchases do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :invoice_number
      t.date :purchase_date
      t.decimal :subtotal
      t.decimal :discount
      t.decimal :tax
      t.decimal :total_amount
      t.decimal :paid_amount
      t.decimal :due_amount
      t.string :status
      t.text :notes

      t.timestamps
    end
  end
end
