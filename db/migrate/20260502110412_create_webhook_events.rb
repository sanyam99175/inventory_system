class CreateWebhookEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :webhook_events do |t|
      t.string :stripe_event_id
      t.string :event_type

      t.timestamps
    end
  end
end
