class AddOrganizationToRequests < ActiveRecord::Migration[7.1]
  def change
    add_reference :requests, :organization, null: false, foreign_key: true
  end
end
