class User < ApplicationRecord
  acts_as_paranoid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  belongs_to :organization, optional: true
  validates :organization, presence: true, unless: :superadmin_user?

  enum role: { worker: 0, owner: 1, superadmin: 2 }

  PERMISSION_MODULES = {
    products: ["view", "create_update", "delete"],
    requests: ["view", "update"],
    alerts: ["view"],
    history: ["view"],
    trends: ["view"],
    intelligence: ["view"],
    recycle_bin: ["view", "restore"],
    audits: ["view"],
    users: ["view", "create_update", "delete", "change_permissions"],
    manage_subscription: ["view"]
  }

  has_one :notification_preference
  has_many :requests, dependent: :nullify
  has_many :notifications, dependent: :destroy
  has_many :histories, dependent: :nullify
  has_many :stock_requests, dependent: :nullify
  has_many :audit_logs, dependent: :nullify

  before_create :set_default_permissions
  before_save :normalize_permissions
  after_create :create_default_notification_preference, if: :owner?
  after_create :send_welcome_email

  def create_default_notification_preference
    NotificationPreference.find_or_create_by!(
      user: self,
      organization: organization,
      low_stock_alert: false,
      email: false,
      whatsapp: false
    )
  end


  def send_welcome_email
    user = self
    email = NotificationMailer.new.welcome(user)
    EmailSender.send_with_retry(
      to: user.email,
      subject: email[:subject],
      html: email[:html],
      text: email[:text]
    )
  end

  def superadmin_user?
    self.superadmin?
  end

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
        if %w[products requests users].include?(key.to_s)
          ["view"]
        else
          []
        end
      end
    end
  end

  private

  def get_current_user_id
    Thread.current[:current_user]&.id
  end

end
