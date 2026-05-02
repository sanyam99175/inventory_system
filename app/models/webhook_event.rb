class WebhookEvent < ApplicationRecord
  validates :stripe_event_id, uniqueness: true
end