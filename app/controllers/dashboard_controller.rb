class DashboardController < ApplicationController
  def index
    @products = current_organization.products
    @requests = current_organization.requests

    @low_stock_products = current_organization
                            .products
                            .where("stock_count <= alert_limit")

            # last 7 days range
    range = 7.days.ago..Time.current

    @weekly_stock_added =
      @requests.where(status: :approved, created_at: range)
              .where("quantity_change > 0")
              .sum(:quantity_change)

    @weekly_stock_removed =
      @requests.where(status: :approved, created_at: range)
              .where("quantity_change < 0")
              .sum("ABS(quantity_change)")

    @weekly_requests_processed =
      @requests.where(status: [:approved, :rejected], created_at: range).count

    @weekly_low_stock =
      @products.where("stock_count <= alert_limit")
              .where(updated_at: range)
              .count

    @pending_purchases = current_organization.purchases
      .includes(:supplier)
      .where("COALESCE(paid_amount, 0) < total_amount")
      .order(created_at: :desc)

    @total_due_amount = @pending_purchases.sum do |p|
      p.total_amount.to_f - p.paid_amount.to_f
    end

    if current_user.owner?
        render "owner/dashboard"
    else
        render "worker/dashboard"
    end
  end
end