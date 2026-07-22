class CreateDemandItems < ActiveRecord::Migration[7.1]
  def change
    create_table :demand_items do |t|
      t.references :demand, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity
      t.text :notes

      t.timestamps
    end
  end
end
