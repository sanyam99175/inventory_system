class WorkerController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_worker!

  def dashboard
    if params[:search].present?
      @products = Product.where("name ILIKE ?", "%#{params[:search]}%")
    else
      @products = Product.all
    end
  end

  private

  def authorize_worker!
    redirect_to root_path, alert: "Not authorized" unless current_user.worker?
  end
end