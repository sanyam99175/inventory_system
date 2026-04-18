class RequestsController < ApplicationController
  before_action :authenticate_user!

  def create
    product = Product.find(request_params[:product_id])
    quantity_change = request_params[:quantity_change].to_i

    new_stock = product.stock_count + quantity_change

    if new_stock < 0
      redirect_to product_path(product),
                  alert: "❌ Cannot create request: stock will go below zero"
      return
    end

    @request = current_user.requests.new(request_params)
    @request.status = :pending

    if @request.save
      redirect_to worker_dashboard_path, notice: "Request sent for approval"
    else
      redirect_to product_path(product),
                  alert: @request.errors.full_messages.join(", ")
    end
  end

  def approve
    request = Request.find(params[:id])
    product = request.product

    if product.stock_count + request.quantity_change < 0
      redirect_to owner_dashboard_path, alert: "Stock cannot go below zero"
      return
    end

    ActiveRecord::Base.transaction do
      product.update!(stock_count: product.stock_count + request.quantity_change)
      request.update!(status: :approved)
      AuditLog.create(
        record_type: 'Request',
        record_id: request.id,
        action: 'approve_request',
        details: product.name,
        user_id: current_user.id
      )
    end

    redirect_to owner_dashboard_path, notice: "Request approved"
  end

  def reject
    request = Request.find(params[:id])
    product = request.product

    request.update!(status: :rejected)
    AuditLog.create(
      record_type: 'Request',
      record_id: request.id,
      action: 'reject_request',
      details: product.name,
      user_id: current_user.id
    )

    redirect_to owner_dashboard_path, notice: "Request rejected"
  end

  def cancel
    request = Request.find(params[:id])
    product = request.product

    if request.pending?
      request.update(status: :cancelled)
      AuditLog.create(
        record_type: 'Request',
        record_id: request.id,
        action: 'cancel_request',
        details: product.name,
        user_id: current_user.id
      )
    end

    redirect_back fallback_location: root_path
  end

  def update
    @request = Request.find(params[:id])

    if current_user.owner?
      if params[:approve]
        @request.update(status: "approved")
        update_product_stock(@request)
      elsif params[:reject]
        @request.update(status: "rejected")
      end
    end

    redirect_to owner_dashboard_path
  end

  private

  def request_params
    params.require(:request).permit(:product_id, :quantity_change)
  end

  def update_product_stock(request)
    product = request.product
    product.update(stock_count: product.stock_count + request.quantity_change)
  end
end