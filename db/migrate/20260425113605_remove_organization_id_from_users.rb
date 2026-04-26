class RemoveOrganizationIdFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_reference :users, :organization, foreign_key: true
  end
end
