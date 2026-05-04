class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_current_organization
  before_action :ensure_user_belongs_to_org
  before_action :block_suspended_org, unless: :devise_controller?
  before_action :check_subscription
  before_action :sync_subscription_if_needed
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_global_counts
  before_action :set_locale
  before_action :set_notification_preference

  helper_method :current_organization

  # -----------------------------------
  # NOTIFICATIONS
  # -----------------------------------
  def set_notification_preference
    return unless current_user && current_organization

    @preference = NotificationPreference.find_or_initialize_by(
      user: current_user,
      organization: current_organization
    )
  end

  def block_suspended_org
    return unless current_user
    return if current_user.superadmin?

    org = current_user.organization
    return unless org&.account_status == "suspended"

    # ✅ allow public + safe controllers
    return if devise_controller?
    return if controller_name.in?(%w[home plans])
    return if request.path == "/suspended"

    redirect_to "/suspended", alert: "Your account has been suspended"
  end

  # -----------------------------------
  # STRIPE SYNC (DEV ONLY SAFE HELPER)
  # -----------------------------------
  def sync_subscription_if_needed
    return unless Rails.env.development?
    return unless current_organization&.stripe_subscription_id

    refresh_subscription!(current_organization)
  end

  def refresh_subscription!(org)
    sub = Stripe::Subscription.retrieve(org.stripe_subscription_id)

    trial_end_time = sub.trial_end.present? ? Time.at(sub.trial_end) : nil

    org.update!(
    trial_ends_at: trial_end_time,
    subscription_status: sub.status
    )
  end

  # -----------------------------------
  # 🔥 CORE ACCESS CONTROL (FIXED)
  # -----------------------------------
  def check_subscription
    return if current_user&.superadmin?
    return unless current_organization

    # NEVER block system routes
    return if devise_controller?
    return if controller_name.in?(%w[billing webhooks subscriptions])
    return if request.path.include?("stripe")

    org = current_organization

    return if org.access_allowed?

    # ----------------------------
    # 5. EVERYTHING ELSE → BLOCK + BILLING
    # ----------------------------
    redirect_to billing_checkout_path(
      organization_id: org.id,
      price_id: org.price_id_for(org.plan)
    )
  end

  # -----------------------------------
  # 🏢 ORGANIZATION CONTEXT
  # -----------------------------------
  def set_current_organization
    return unless user_signed_in?
    return if current_user.superadmin?

    return if devise_controller?
    return if request.path.start_with?("/admin")
    return if controller_name.in?(%w[home organizations plans])

    org_id = params[:organization_id] || session[:organization_id]

    if org_id.blank?
      org = current_user.organization

      if org
        session[:organization_id] = org.id
        @current_organization = org
        return
      else
        redirect_to root_path, alert: "Organization not selected"
        return
      end
    end

    org = Organization.find_by(id: org_id)

    unless org
      reset_session
      redirect_to root_path, alert: "Invalid organization"
      return
    end

    # IMPORTANT FIX: allow ownership or membership logic later
    unless current_user.organization_id == org.id
      reset_session
      redirect_to root_path, alert: "Access denied"
      return
    end

    session[:organization_id] = org.id
    @current_organization = org
  end

  def current_organization
    @current_organization
  end

  def ensure_user_belongs_to_org
    return if current_user&.superadmin?
    return unless current_organization

    unless current_user.organization_id == current_organization.id
      reset_session
      redirect_to root_path, alert: "Access denied"
    end
  end

  # -----------------------------------
  # GLOBAL COUNTS
  # -----------------------------------
  def set_global_counts
    return unless current_organization

    @low_stock_count =
      current_organization.products.where("stock_count <= alert_limit").count

    @pending_requests_count =
      current_organization.requests.pending.count
  end

  # -----------------------------------
  # DEVISE PARAMS
  # -----------------------------------
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  # -----------------------------------
  # LOCALE
  # -----------------------------------
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    opts = { locale: I18n.locale }

    unless devise_controller? || request.path.start_with?("/admin")
      opts[:organization_id] = current_organization.id if current_organization
    end

    opts
  end
end