class AddOrganizationToStockRequests < ActiveRecord::Migration[7.1]
  def change
    add_reference :stock_requests, :organization, null: false, foreign_key: true
  end
end
