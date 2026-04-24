class AddOrganizationToProductTypes < ActiveRecord::Migration[7.1]
  def change
    add_reference :product_types, :organization, null: false, foreign_key: true
  end
end
