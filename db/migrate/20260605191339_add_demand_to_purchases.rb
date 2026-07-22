class AddDemandToPurchases < ActiveRecord::Migration[7.1]
  def change
    add_reference :purchases, :demand, foreign_key: true
  end
end
