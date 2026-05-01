class AddOrganizationToNotificationPreferences < ActiveRecord::Migration[7.1]
  def change
    add_reference :notification_preferences, :organization, null: false, foreign_key: true
  end
end
