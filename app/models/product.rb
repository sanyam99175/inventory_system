class Product < ApplicationRecord
  acts_as_paranoid

  belongs_to :organization
  belongs_to :product_type

  has_many :requests
  has_many :histories

  validates :name, :stock_count, :godown_number, :product_type_id, presence: true

  after_commit :clear_cache
  after_create :log_product_creation
  after_update :log_product_update
  before_destroy :log_product_deletion

  private

  def get_current_user_id
    Thread.current[:current_user]&.id
  end

  def clear_cache
    return unless organization_id

    Rails.cache.delete("org:#{organization_id}:products_count")
    Rails.cache.delete("org:#{organization_id}:low_stock_count")
  end

  def log_product_creation
    AuditLog.create!(
      record_type: 'Product',
      record_id: id,
      action: 'create',
      details: name,
      user_id: get_current_user_id,
      organization_id: organization_id
    )
  end

  def log_product_update
    AuditLog.create!(
      record_type: 'Product',
      record_id: id,
      action: 'update',
      details: name,
      user_id: get_current_user_id,
      organization_id: organization_id
    )
  end

  def log_product_deletion
    AuditLog.create!(
      record_type: 'Product',
      record_id: id,
      action: 'delete',
      details: name,
      user_id: get_current_user_id,
      organization_id: organization_id
    )
  end
end