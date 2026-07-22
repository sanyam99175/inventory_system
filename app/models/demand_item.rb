class DemandItem < ApplicationRecord
  belongs_to :demand
  belongs_to :product

  validates :quantity, presence: true, numericality: { greater_than: 0 }
end