class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :product_types, dependent: :destroy
  has_many :requests, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :histories, dependent: :destroy
  has_many :stock_requests, dependent: :destroy
  has_many :audit_logs, dependent: :destroy

  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: true

  def can_use?(feature)
    case plan
    when "free"
      %w[products requests].include?(feature)
    when "basic"
      %w[products requests history trends].include?(feature)
    when "premium"
      true
    end
  end
end
