class AddProductNameToRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :requests, :product_name, :string
  end
end
