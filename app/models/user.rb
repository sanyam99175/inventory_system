class User < ApplicationRecord
  acts_as_paranoid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { worker: 0, owner: 1 }

  PERMISSION_MODULES = {
    "products" => "Products",
    "requests" => "Requests",
    "history" => "History",
    "alerts" => "Alerts",
    "trends" => "Trends",
    "recycle_bin" => "Recycle Bin",
    "audits" => "Audits",
    "users" => "Users"
  }.freeze

  has_many :requests, dependent: :nullify
  has_many :notifications, dependent: :destroy
  has_many :histories, dependent: :nullify
  has_many :stock_requests, dependent: :nullify
  has_many :audit_logs, dependent: :nullify

  after_create :log_user_creation
  after_update :log_user_update
  before_destroy :log_user_deletion

  def permission_enabled?(key)
    permissions_hash[key.to_s]
  end

  def permissions_hash
    if self[:permissions].present?
      self[:permissions].with_indifferent_access
    else
      default_permissions
    end
  end

  def default_permissions
    if owner?
      PERMISSION_MODULES.keys.index_with { true }
    else
      PERMISSION_MODULES.keys.index_with { |key| %w[products].include?(key) }
    end
  end

  private

  def get_current_user_id
    Thread.current[:current_user]&.id
  end

  def log_user_creation
    AuditLog.create(
      record_type: 'User',
      record_id: id,
      action: 'create',
      details: email,
      user_id: get_current_user_id
    )
  end

  def log_user_update
    # Skip audit logging for login-related updates (Devise tracking fields)
    login_only_fields = %w[current_sign_in_at last_sign_in_at sign_in_count current_sign_in_ip last_sign_in_ip]
    changed_fields = saved_changes.keys
    
    # Only log if non-login fields were changed
    return if (changed_fields - login_only_fields).empty?
    
    AuditLog.create(
      record_type: 'User',
      record_id: id,
      action: 'update',
      details: "#{email} (Role: #{role.titleize})",
      user_id: get_current_user_id
    )
  end

  def log_user_deletion
    AuditLog.create(
      record_type: 'User',
      record_id: id,
      action: 'delete',
      details: email,
      user_id: get_current_user_id
    )
  end
end
