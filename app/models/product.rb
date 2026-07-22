class Product < ApplicationRecord
  acts_as_paranoid

  belongs_to :organization
  belongs_to :product_type

  has_many :requests
  has_many :histories
  has_many :purchase_items

  belongs_to :supplier
  validates :name, :godown_number, :product_type_id, presence: true
  validates :supplier_id, presence: true
  validates :name , uniqueness: { scope: :organization_id }
  validates :stock_count, presence: true,
                        numericality: { greater_than_or_equal_to: 0 }

  before_create :set_defaults
  after_commit :clear_cache
  after_update_commit :check_low_stock

  def set_defaults
    self.stock_count ||= 0
    self.alert_limit ||= 0
  end

  def daily_usage_rate
    usage = requests.where(created_at: 30.days.ago..Time.current)
                    .sum("ABS(quantity_change)")

    (usage / 30.0)
  end

  def days_remaining
    return 9999 if daily_usage_rate.zero?
    (stock_count / daily_usage_rate).round
  end

  def recommended_stock
    (daily_usage_rate * 30 * 1.2).round
  end

  # =========================
  # LAST PURCHASE ITEM
  # =========================
  def last_purchase_item
    purchase_items
      .includes(:purchase)
      .order("purchases.purchase_date DESC")
      .references(:purchase)
      .first
  end

  # =========================
  # SUGGESTED SUPPLIER
  # =========================
  def suggested_supplier
    last_purchase_item&.purchase&.supplier
  end

  # =========================
  # LAST PURCHASE PRICE
  # =========================
  def last_purchase_price
    last_purchase_item&.unit_price
  end

  # =========================
  # LAST PURCHASE DATE
  # =========================
  def last_purchase_date
    last_purchase_item&.purchase&.purchase_date
  end

  def reorder_needed?
    stock_count <= alert_limit || days_remaining < 7
  end

  def check_low_stock
    return unless saved_change_to_stock_count?

    if stock_count < alert_limit &&
      stock_count_before_last_save >= alert_limit

      WhatsappNotifier.send_low_stock_alert(self)
      LowStockAlertJob.perform_later(id)
    end
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