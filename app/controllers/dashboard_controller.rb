class DashboardController < ApplicationController
  def index
    @products = current_organization.products
    @requests = current_organization.requests

    @low_stock_products = current_organization
                            .products
                            .where("stock_count <= alert_limit")

    if current_user.owner?
        render "owner/dashboard"
    else
        render "worker/dashboard"
    end
  end
end