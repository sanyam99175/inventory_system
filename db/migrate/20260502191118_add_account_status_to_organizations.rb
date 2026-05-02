class AddAccountStatusToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :account_status, :string
  end
end
