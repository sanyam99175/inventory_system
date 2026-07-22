class Demand < ApplicationRecord
  belongs_to :organization
  belongs_to :supplier

  has_many :demand_items, dependent: :destroy
  has_many :products, through: :demand_items
  belongs_to :purchase, optional: true
  validates :demand_date, presence: true

  enum status: {
    generated: 0,
    executed: 1
  }

  accepts_nested_attributes_for :demand_items, allow_destroy: true
  before_validation :set_default_status, on: :create

  def set_default_status
    self.status ||= :generated
  end

  def convertible?
    generated? && purchase_id.nil?
  end

  def mark_as_converted!(purchase)
    return false unless convertible?

    transaction do
      update!(
        purchase_id: purchase.id,
        status: :executed,
        converted_at: Time.current
      )
    end
  end
end