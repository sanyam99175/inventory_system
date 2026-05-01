class AddTrialUsedToOrganizations < ActiveRecord::Migration[7.1]
  def change
    add_column :organizations, :trial_used, :boolean
  end
end
