class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_current_organization
  before_action :ensure_user_belongs_to_org
  before_action :check_subscription
  before_action :sync_subscription_if_needed
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_global_counts
  before_action :set_locale
  before_action :set_notification_preference

  helper_method :current_organization

  # -----------------------------------
  # SUBSCRIPTION CONTROL (UNCHANGED)
  # -----------------------------------

  def set_notification_preference
    return unless current_user && current_organization

    @preference = NotificationPreference.find_or_initialize_by(
        user: current_user,
        organization: current_organization
    )
  end

  def sync_subscription_if_needed
    return unless Rails.env.development?
    return unless current_organization&.stripe_subscription_id
    return unless current_organization.trialing?

    refresh_subscription!(current_organization)
  end

  def refresh_subscription!(org)
    sub = Stripe::Subscription.retrieve(org.stripe_subscription_id)

    org.update!(
      trial_ends_at: Time.at(sub.trial_end),
      subscription_status: sub.status
    )
  end

  def check_subscription
    return if current_user&.superadmin?
    return unless current_organization

    # ✅ Allow safe paths
    return if devise_controller?
    return if controller_name.in?(%w[billing webhooks subscriptions])
    return if request.path.include?("stripe")

    org    = current_organization
    if org.subscription_status == "incomplete"
        redirect_to billing_checkout_path(price_id: org.price_id_for(org.plan)),
                    alert: "Please complete your payment"
        return
    end

    status = org.subscription_status
    plan   = org.plan

    # ✅ Free plan allowed
    return if plan == "free"

    # 🧠 Use Stripe time in dev
    now = Rails.env.development? ? org.stripe_now : Time.current

    # ❌ Trial expired
    if org.trial_ends_at.present? && now > org.trial_ends_at
      reset_session
      redirect_to root_url, alert: "Trial expired. Please upgrade."
      return
    end

    # ✅ Active subscription
    return if status == "active"

    # ⚠️ Trial still valid
    return if status == "trialing"

    # ⚠️ Payment failed
    if status == "past_due"
      flash.now[:alert] = "Payment failed. Please update your billing."
      return
    end

    # ❌ Everything else
    reset_session
  end

  # -----------------------------------
  # 🏢 ORGANIZATION CONTEXT (FIXED)
  # -----------------------------------

  def set_current_organization
    return unless user_signed_in?
    return if current_user.superadmin?

    # ✅ Skip for non-org routes
    return if devise_controller?
    return if request.path.start_with?("/admin")
    return if controller_name.in?(%w[home organizations plans])

    org_id = params[:organization_id] || session[:organization_id]

    # ✅ If missing, try fallback (VERY IMPORTANT)
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

    unless current_user.organization_id == org.id
        reset_session
        redirect_to root_path, alert: "Access denied"
        return
    end

    # ✅ success
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
      current_organization.products
                          .where("stock_count <= alert_limit")
                          .count

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
  # I18N
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