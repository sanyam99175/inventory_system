class CreateSuppliers < ActiveRecord::Migration[7.1]
  def change
    create_table :suppliers do |t|
      t.string :name
      t.string :phone
      t.string :email
      t.string :gst_number
      t.text :address
      t.text :notes
      t.boolean :active
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end
  end
end
