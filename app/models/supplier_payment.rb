class SupplierPayment < ApplicationRecord
  belongs_to :organization
  belongs_to :supplier
  belongs_to :purchase
  belongs_to :user
end