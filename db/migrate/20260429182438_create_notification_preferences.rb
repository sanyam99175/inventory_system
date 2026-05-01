class CreateNotificationPreferences < ActiveRecord::Migration[7.1]
  def change
    create_table :notification_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.boolean :email
      t.boolean :whatsapp
      t.boolean :low_stock_alert

      t.timestamps
    end
  end
end
