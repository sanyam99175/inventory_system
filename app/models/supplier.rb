class Supplier < ApplicationRecord
  belongs_to :organization

  has_many :products
  has_many :purchases, dependent: :destroy
  has_many :supplier_payments, dependent: :destroy

  validates :name, presence: true

  # =========================
  # ANALYTICS
  # =========================

  def total_purchase_amount
    purchases.sum(:total_amount)
  end

  def total_paid_amount
    purchases.sum(:paid_amount)
  end

  def total_due_amount
    purchases.sum(:due_amount)
  end
end