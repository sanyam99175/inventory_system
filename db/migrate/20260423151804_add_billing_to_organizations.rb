class AddBillingToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :plan, :string, default: "free"
    add_column :organizations, :stripe_customer_id, :string
    add_column :organizations, :stripe_subscription_id, :string
    add_column :organizations, :subscription_status, :string
  end
end
