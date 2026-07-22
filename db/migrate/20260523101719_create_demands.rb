class CreateDemands < ActiveRecord::Migration[7.1]
  def change
    create_table :demands do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.integer :status
      t.date :demand_date
      t.text :notes

      t.timestamps
    end
  end
end
