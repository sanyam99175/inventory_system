class ProductType < ApplicationRecord
    belongs_to :organization
    has_many :products

    validates :name, presence: true, uniqueness: { scope: :organization_id }
end
