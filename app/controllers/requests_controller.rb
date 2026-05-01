class RequestsController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.owner?
      @requests = current_organization.requests.order(created_at: :desc)
    else
      @requests = current_user.requests.order(created_at: :desc)
    end
  end

  # ========================
  # CREATE REQUEST
  # ========================
  def create
    product = current_organization.products.find(request_params[:product_id])
    quantity_change = request_params[:quantity_change].to_i

    new_stock = product.stock_count + quantity_change

    if new_stock < 0
      redirect_to product_path(product),
                  alert: t('cannot_create_request_stock_below_zero')
      return
    end

    @request = current_user.requests.new(request_params)
    @request.status = :pending
    @request.organization_id = current_organization.id

    if @request.save
      log_request_audit(
        action: "create",
        request: @request,
        product: product,
        changes: {
          quantity_change: { before: nil, after: quantity_change },
          status: { before: nil, after: "pending" }
        }
      )

      redirect_to dashboard_path, notice: t('request_sent_for_approval')
    else
      redirect_to product_path(product),
                  alert: @request.errors.full_messages.join(", ")
    end
  end

  # ========================
  # APPROVE
  # ========================
  def approve
    request = current_organization.requests.find(params[:id])
    product = request.product

    if product.stock_count + request.quantity_change < 0
      redirect_to dashboard_path, alert: t('stock_cannot_go_below_zero')
      return
    end

    ActiveRecord::Base.transaction do
      old_stock = product.stock_count

      product.update!(stock_count: old_stock + request.quantity_change)
      request.update!(status: :approved)

      # 🔥 Request audit
      log_request_audit(
        action: "approve_request",
        request: request,
        product: product,
        changes: {
          status: { before: "pending", after: "approved" }
        }
      )

      # 🔥 Product stock audit (IMPORTANT)
    AuditLog.create(
      record_type: "Product",
      record_id: product.id,
      action: "update_stock",
      details: {
        stock: {
          before: old_stock,
          after: product.stock_count
        },
        meta: audit_meta(product.name).merge(
          source: "request_approval",
          request_id: request.id,
          requested_by: request.user&.name
        )
      },
      user_id: current_user.id,
      organization_id: current_organization.id
    )
    end

    redirect_to dashboard_path, notice: t('request_approved')
  end

  # ========================
  # REJECT
  # ========================
  def reject
    request = current_organization.requests.find(params[:id])
    product = request.product

    request.update!(status: :rejected)

    log_request_audit(
      action: "reject_request",
      request: request,
      product: product,
      changes: {
        status: { before: "pending", after: "rejected" }
      }
    )

    redirect_to dashboard_path, notice: t('request_rejected')
  end

  # ========================
  # CANCEL
  # ========================
  def cancel
    request = current_organization.requests.find(params[:id])
    product = request.product

    if request.pending?
      request.update!(status: :cancelled)

      log_request_audit(
        action: "cancel_request",
        request: request,
        product: product,
        changes: {
          status: { before: "pending", after: "cancelled" }
        }
      )
    end

    redirect_back fallback_location: root_path
  end

  # ========================
  # LEGACY UPDATE (optional)
  # ========================
  def update
    @request = current_organization.requests.find(params[:id])

    return redirect_to dashboard_path unless current_user.owner?

    if params[:approve]
      approve
    elsif params[:reject]
      reject
    end
  end

  private

  def request_params
    params.require(:request).permit(:product_id, :quantity_change)
  end

  # ========================
  # 🔥 AUDIT LOGGER
  # ========================
  def log_request_audit(action:, request:, product:, changes:)
    AuditLog.create(
      record_type: "Request",
      record_id: request.id,
      action: action,
      details: changes.merge(
        meta: audit_meta(product.name, request)
      ),
      user_id: current_user.id,
      organization_id: current_organization.id
    )
  end

  def audit_meta(product_name, request = nil)
    {
      performed_by_id: current_user.id,
      performed_by_name: current_user.name || current_user.email,
      product_name: product_name,
      request_id: request&.id
    }
  end
end