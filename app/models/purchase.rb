class Purchase < ApplicationRecord
  belongs_to :organization
  belongs_to :supplier
  belongs_to :user

  # Demand association (important for conversion flow)
  belongs_to :demand, optional: true

  has_many :purchase_items, dependent: :destroy
  has_many :supplier_payments, dependent: :destroy

  has_one_attached :invoice

  accepts_nested_attributes_for :purchase_items,
                                allow_destroy: true,
                                reject_if: :all_blank

  validates :purchase_date, presence: true

  enum status: {
    unpaid: "unpaid",
    partial: "partial",
    paid: "paid"
  }

  before_validation :calculate_totals

  # =========================
  # GUARD: prevent editing executed demand purchases
  # =========================
  def prevent_after_execution_changes
    return unless demand&.executed?

    errors.add(:base, "Cannot modify purchase after demand execution")
    throw(:abort)
  end

  # =========================
  # TOTAL CALCULATION
  # =========================
  def calculate_totals
    self.subtotal = self.total_amount

    self.discount ||= 0
    self.tax ||= 0
    self.paid_amount ||= 0

    self.total_amount = subtotal.to_f - discount.to_f + tax.to_f
    self.due_amount = total_amount.to_f - paid_amount.to_f

    self.status =
      if due_amount <= 0
        "paid"
      elsif paid_amount.to_f > 0
        "partial"
      else
        "unpaid"
      end
  end
end