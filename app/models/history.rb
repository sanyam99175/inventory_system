class History < ApplicationRecord
  belongs_to :organization
  belongs_to :user
  belongs_to :product
end
