class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :authorize_view, only: [:index, :show]
  before_action :authorize_create_update, only: [:new, :create, :edit, :update, :update_stock]
  before_action :authorize_delete, only: [:destroy]

  def index
    scope = current_organization.products.includes(:product_type, :requests)

    if params[:search].present?
      scope = scope.where("products.name ILIKE ?", "%#{params[:search]}%")
    end

    if params[:product_type_id].present?
      scope = scope.where(product_type_id: params[:product_type_id])
    end

    @products = scope.order(created_at: :desc)

    @show_early_stage_warning =
      current_organization.created_at > 30.days.ago ||
      current_organization.requests.count < 100

    enrich_inventory_intelligence
  end

  # ================= INVENTORY INTELLIGENCE (ADDED ONLY) =================
  def enrich_inventory_intelligence
    @products = @products.map do |product|

      usage_last_30_days = product.requests
                                  .where(created_at: 30.days.ago..Time.current)
                                  .sum("ABS(quantity_change)")

      daily_usage_rate = usage_last_30_days.to_f / 30.0

      days_remaining =
        if daily_usage_rate > 0
          (product.stock_count / daily_usage_rate).round
        else
          9999
        end

      recommended_stock = (daily_usage_rate * 30 * 1.2).round

      reorder_needed =
        product.stock_count <= product.alert_limit || days_remaining < 7

      product.define_singleton_method(:daily_usage_rate) { daily_usage_rate }
      product.define_singleton_method(:days_remaining) { days_remaining }
      product.define_singleton_method(:recommended_stock) { recommended_stock }
      product.define_singleton_method(:reorder_needed?) { reorder_needed }

      product
    end
  end

  def show; end

  def new
    @product = current_organization.products.new
  end

  def create
    @product = current_organization.products.build(product_params)

    if @product.save

      AuditLogger.log(
        record: @product,
        action: "create",
        user: current_user,
        organization: current_organization,
        changes: {
          name: { before: nil, after: @product.name },
          stock_count: { before: nil, after: @product.stock_count },
          godown_number: { before: nil, after: @product.godown_number },
          alert_limit: { before: nil, after: @product.alert_limit },
          product_type_id: { before: nil, after: @product.product_type_id }
        },
        meta: {
          performed_by_name: current_user.name
        }
      )

      redirect_to @product, notice: t('product_created_successfully')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    old_data = @product.attributes

    if @product.update(product_params)

      diff = AuditLogger.diff(old_data, @product.attributes)

      AuditLogger.log(
        record: @product,
        action: "update",
        user: current_user,
        organization: current_organization,
        changes: diff
      )

      redirect_to @product, notice: t('product_updated_successfully')
    else
      render :edit
    end
  end

  def update_stock
    @product = current_organization.products.find(params[:id])
    quantity = params[:quantity_change].to_i

    old_stock = @product.stock_count
    new_stock = old_stock + quantity

    performed_by_id = params[:performed_by_user_id].to_i
    performed_by_id = current_user.id if performed_by_id.zero?

    performed_by = User.find(performed_by_id)

    if new_stock < 0
      redirect_to @product, alert: t('stock_cannot_go_below_zero')
      return
    end

    @product.update(stock_count: new_stock)

    # ================= AUDIT (KEPT AS IS) =================
    AuditLogger.log(
      record: @product,
      action: "update_stock",
      user: current_user,
      organization: current_organization,
      changes: {
        stock_count: {
          before: old_stock,
          after: new_stock
        }
      },
      meta: {
        quantity_change: quantity,
        performed_for_user_id: performed_by_id,
        performed_by_name: current_user.name,
        performed_for_name: performed_by.name
      }
    )

    Request.create!(
      user: performed_by,
      product: @product,
      quantity_change: quantity,
      status: :approved,
      allow_positive_quantity: true,
      organization_id: current_organization.id
    )

    redirect_to @product, notice: t('stock_updated_successfully')
  end

  def destroy
    snapshot = @product.attributes

    AuditLogger.log(
      record: @product,
      action: "destroy",
      user: current_user,
      organization: current_organization,
      changes: {
        name: { before: snapshot["name"], after: nil },
        stock_count: { before: snapshot["stock_count"], after: nil },
        godown_number: { before: snapshot["godown_number"], after: nil },
        alert_limit: { before: snapshot["alert_limit"], after: nil }
      },
      meta: {
        performed_by_name: current_user.name
      }
    )

    @product.destroy

    redirect_to products_path, notice: t('product_deleted_successfully')
  end

  private

  def set_product
    @product = current_organization.products.find(params[:id])
  end

  def authorize_view
    redirect_to root_path unless current_user.has_permission?("products", "view")
  end

  def authorize_create_update
    redirect_to root_path unless current_user.has_permission?("products", "create_update")
  end

  def authorize_delete
    redirect_to root_path unless current_user.has_permission?("products", "delete")
  end

  def product_params
    params.require(:product).permit(:name, :stock_count, :godown_number, :alert_limit, :product_type_id)
  end
end