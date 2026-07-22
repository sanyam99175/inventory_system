class AddConversionFieldsToDemands < ActiveRecord::Migration[7.1]
  def change
    add_column :demands, :purchase_id, :integer
    add_column :demands, :converted_at, :datetime

    add_index :demands, :purchase_id
  end
end
