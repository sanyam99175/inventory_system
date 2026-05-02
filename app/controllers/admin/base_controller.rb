class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_superadmin!
  before_action :ensure_not_in_subdomain 

  private

  def require_superadmin!
    unless current_user&.superadmin?
      redirect_to root_url(subdomain: nil), alert: "Access denied"
    end
  end

  def ensure_not_in_subdomain
    if request.subdomain.present?
        redirect_to root_url(subdomain: nil)
    end
  end
end