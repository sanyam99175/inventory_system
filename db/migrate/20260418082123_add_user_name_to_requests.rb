class AddUserNameToRequests < ActiveRecord::Migration[7.1]
  def change
    add_column :requests, :user_name, :string
  end
end
