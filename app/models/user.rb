class User < ApplicationRecord
  acts_as_paranoid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :organization

  enum role: { worker: 0, owner: 1 }

  PERMISSION_MODULES = {
    products: ["view", "create_update", "delete"],
    requests: ["view", "update"],
    alerts: ["view"],
    history: ["view"],
    trends: ["view"],
    recycle_bin: ["view", "restore"],
    audits: ["view"],
    users: ["view", "create_update", "delete", "change_permissions"]
  }

  has_many :requests, dependent: :nullify
  has_many :notifications, dependent: :destroy
  has_many :histories, dependent: :nullify
  has_many :stock_requests, dependent: :nullify
  has_many :audit_logs, dependent: :nullify

  before_create :set_default_permissions
  before_save :normalize_permissions
  after_create :log_user_creation
  after_update :log_user_update
  before_destroy :log_user_deletion

  def set_default_permissions
    return if self.permissions.present? # don't override if already set

    self.permissions = default_permissions
  end

  def normalize_permissions
    return if permissions.blank?

    permissions.each do |key, perms|
      case perms
      when true
        permissions[key] = ["all"]
      when false
        permissions[key] = []
      end
    end
  end

  def permissions_hash
    raw = self[:permissions]

    if raw.present?
      raw.with_indifferent_access
    else
      default_permissions.with_indifferent_access
    end
  end
  
  def has_permission?(module_key, action)
    perms = permissions_hash[module_key.to_s]

    return false if perms.blank?

    # fallback for old boolean data
    return true if perms == true

    perms.include?("all") || perms.include?(action.to_s)
  end

  def permission_enabled?(key)
    perms = permissions_hash[key.to_s]
    perms.present?
  end

  def default_permissions
    if owner?
      User::PERMISSION_MODULES.transform_values(&:dup)
    else
      User::PERMISSION_MODULES.keys.index_with do |key|
        key.to_s == "products" ? ["view"] : []
      end
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
      user_id: get_current_user_id,
      organization_id: organization_id
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
      user_id: get_current_user_id,
      organization_id: organization_id
    )
  end

  def log_user_deletion
    AuditLog.create(
      record_type: 'User',
      record_id: id,
      action: 'delete',
      details: email,
      user_id: get_current_user_id,
      organization_id: organization_id
    )
  end
end
