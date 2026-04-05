class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :request

  enum status: { active: 0, cleared: 1 }
end
