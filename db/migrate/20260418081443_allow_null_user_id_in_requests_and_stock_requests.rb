class AllowNullUserIdInRequestsAndStockRequests < ActiveRecord::Migration[7.1]
  def change
    change_column_null :requests, :user_id, true
    change_column_null :stock_requests, :user_id, true
  end
end
