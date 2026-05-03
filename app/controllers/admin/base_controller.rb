class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_superadmin!

  private

  def require_superadmin!
    unless current_user&.superadmin?
      redirect_to root_url(subdomain: nil), alert: "Access denied"
    end
  end
end