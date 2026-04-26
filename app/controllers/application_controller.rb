class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :set_current_organization
  before_action :ensure_user_belongs_to_org
  before_action :check_subscription 
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_global_counts
  before_action :set_locale

  helper_method :current_organization

  # -----------------------------------
  # ORG CONTEXT
  # -----------------------------------

  def check_subscription
    return unless current_organization

    # allow free plan
    return if current_organization.plan == "free"

    # allow active paid plans
    return if current_organization.active?

    # block access
    redirect_to select_plan_path, alert: "Please upgrade your plan"
  end

  def set_current_organization
    return unless user_signed_in?

    if params[:org_id].present?
        if current_user.organization_id == params[:org_id].to_i
            session[:org_id] = params[:org_id]
        else
            reset_session
            redirect_to root_path, alert: "Access denied"
            return
        end
    end

    @current_organization = current_user.organization
  end


  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def current_organization
    @current_organization
  end

  def ensure_user_belongs_to_org
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

    @low_stock_count = current_organization.products.where("stock_count <= alert_limit").count
    @pending_requests_count = current_organization.requests.pending.count
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end
end