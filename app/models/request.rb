class Request < ApplicationRecord
  belongs_to :user
  belongs_to :product

  enum status: {
    pending: 0,
    approved: 1,
    rejected: 2,
    cancelled: 3
  }

  has_one :notification, dependent: :destroy
  validates :quantity_change, presence: true
  validate :stock_cannot_go_negative

  before_save do
    self.status = status.to_s.strip.downcase
  end

  def stock_cannot_go_negative
    return unless product && quantity_change

    current_stock = product.stock_count
    new_stock = current_stock + quantity_change

    if new_stock < 0
      errors.add(:base, "Current stock is #{current_stock}. It cannot go below zero.")
    end
  end
end
