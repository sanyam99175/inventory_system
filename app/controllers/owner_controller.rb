class OwnerController < ApplicationController
  before_action :authenticate_user!

def dashboard
  @products = Product.all
  @requests = Request.pending
  @low_stock_products = Product.where("stock_count <= alert_limit")
end

  def history
    @requests = Request.includes(:user, :product).order(created_at: :desc)

    if params[:start_date].present? && params[:end_date].present?
      @requests = @requests.where(created_at: params[:start_date]..params[:end_date])
    end
  end

  def alerts
    @products = Product.where("stock_count <= alert_limit")
  end
end