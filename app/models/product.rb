class Product < ApplicationRecord
  belongs_to :product_type
  has_many :requests
  has_many :histories

  validates :name, :stock_count, :godown_number, :product_type_id, presence: true
end
