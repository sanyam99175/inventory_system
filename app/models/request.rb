class Request < ApplicationRecord
  belongs_to :user
  belongs_to :product

  enum status: { pending: 0, approved: 1, rejected: 2 }

  has_one :notification, dependent: :destroy
  validates :quantity_change, presence: true
end
