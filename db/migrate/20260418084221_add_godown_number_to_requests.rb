class AddGodownNumberToRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :requests, :godown_number, :string
  end
end
