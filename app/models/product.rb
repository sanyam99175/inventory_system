class Product < ApplicationRecord
  acts_as_paranoid

  belongs_to :organization
  belongs_to :product_type

  has_many :requests
  has_many :histories

  validates :name, :godown_number, :product_type_id, presence: true
  validates :name , uniqueness: { scope: :organization_id }
  validates :stock_count, presence: true,
                        numericality: { greater_than_or_equal_to: 0 }

  before_create :set_defaults
  after_commit :clear_cache

  private

  def set_defaults
    self.stock_count ||= 0
    self.alert_limit ||= 0
  end

  def get_current_user_id
    Thread.current[:current_user]&.id
  end

  def clear_cache
    return unless organization_id

    Rails.cache.delete("org:#{organization_id}:products_count")
    Rails.cache.delete("org:#{organization_id}:low_stock_count")
  end
end