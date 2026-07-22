class PurchaseItem < ApplicationRecord
  belongs_to :purchase
  belongs_to :product

  validates :quantity, presence: true

  before_validation :calculate_total


  private

  def calculate_total
    self.total_price =
      quantity.to_i * unit_price.to_f
  end
end