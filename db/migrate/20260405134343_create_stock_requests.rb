class CreateStockRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :stock_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.string :status

      t.timestamps
    end
  end
end
