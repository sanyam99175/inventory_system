class WorkerController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_worker!

  def dashboard
    if params[:search].present?
      @products = current_organization.products.where("name ILIKE ?", "%#{params[:search]}%")
    else
      @products = current_organization.products
    end
  end

  private

  def authorize_worker!
    redirect_to root_path, alert: t('not_authorized_worker') unless current_user.worker?
  end
end