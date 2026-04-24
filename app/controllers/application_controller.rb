class ApplicationController < ActionController::Base
  before_action :set_current_organization
  before_action :authenticate_user_if_subdomain, unless: :devise_controller?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_global_counts
  before_action :set_current_user
  after_action :clear_current_user
  before_action :set_locale

  helper_method :current_organization

  protected

  def set_current_organization
    return if main_domain?

    subdomain = request.subdomains.first
    return if subdomain.blank?

    @current_organization = Organization.find_by(subdomain: subdomain)

    unless @current_organization
      redirect_to root_url(subdomain: nil), allow_other_host: true
      return
    end
  end

  def authenticate_user_if_subdomain
    return if main_domain?
    return if request.subdomains.blank?

    unless user_signed_in?
      redirect_to new_user_session_url(subdomain: request.subdomains.first)
      return
    end

    return unless current_user
  end

  def current_organization
    @current_organization
  end

  def set_current_user
    Thread.current[:current_user] = current_user if user_signed_in?
  end

  def clear_current_user
    Thread.current[:current_user] = nil
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def main_domain?
    request.subdomains.blank?
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :role])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def after_sign_in_path_for(resource)
    if resource.organization.present?
      root_url(subdomain: resource.organization.subdomain)
    else
      root_url(subdomain: nil)
    end
  end

  def after_sign_out_path_for(_resource)
    root_url(subdomain: nil)
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def set_global_counts
    return unless user_signed_in? && current_user.owner? && current_organization

    @low_stock_count = current_organization.products.where("stock_count <= alert_limit").count
    @pending_requests_count = current_organization.requests.pending.count
  end
end