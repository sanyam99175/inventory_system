class Request < ApplicationRecord
  attr_accessor :allow_positive_quantity

  belongs_to :organization
  belongs_to :user
  belongs_to :product

  enum status: {
    pending: 0,
    approved: 1,
    rejected: 2,
    cancelled: 3
  }

  has_one :notification, dependent: :destroy
  before_validation :normalize_quantity_change, unless: :allow_positive_quantity
  before_save :set_user_name
  before_save :set_product_name
  before_save :set_godown_number
  validates :quantity_change, presence: true,
                              numericality: { only_integer: true }
  validate :quantity_change_must_be_negative, unless: :allow_positive_quantity
  validate :stock_cannot_go_negative, if: :pending?

  def normalize_quantity_change
    return if quantity_change.blank?

    self.quantity_change = -quantity_change.to_i.abs
  end

  def set_user_name
    return unless user
    self.user_name = user.name.presence || user.email
  end

  def set_product_name
    return unless product
    self.product_name = product.name
  end

  def set_godown_number
    return unless product
    self.godown_number = product.godown_number
  end

  def quantity_change_must_be_negative
    return if quantity_change.blank?
    return if quantity_change.to_i < 0

    errors.add(:quantity_change, "must be a negative number for worker requests")
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
