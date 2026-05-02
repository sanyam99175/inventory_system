class AddDefaultToAccountStatus < ActiveRecord::Migration[7.1]
  def change
    change_column_default :organizations, :account_status, "active"
  end
end
