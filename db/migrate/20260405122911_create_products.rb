class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :name
      t.integer :stock_count
      t.string :godown_number
      t.integer :alert_limit
      t.references :product_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
