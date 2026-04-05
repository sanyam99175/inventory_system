class CreateHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :histories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity_change
      t.string :godown_number
      t.datetime :requested_at

      t.timestamps
    end
  end
end
