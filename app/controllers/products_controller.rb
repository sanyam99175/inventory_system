class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  before_action :authorize_view, only: [:index, :show]
  before_action :authorize_create_update, only: [:new, :create, :edit, :update, :update_stock]
  before_action :authorize_delete, only: [:destroy]

  def index
    scope = current_organization.products

    @products = if params[:search].present?
                  scope.where("name ILIKE ?", "%#{params[:search]}%")
                else
                  scope
                end
  end

  def show; end

  def new
    @product = current_organization.products.new
  end

  def create
    @product = current_organization.products.build(product_params)

    if @product.save
      redirect_to @product, notice: t('product_created_successfully')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: t('product_updated_successfully')
    else
      render :edit
    end
  end

  def update_stock
    @product = current_organization.products.find(params[:id])
    quantity = params[:quantity_change].to_i
    new_stock = @product.stock_count + quantity

    if new_stock < 0
      redirect_to @product, alert: t('stock_cannot_go_below_zero')
      return
    end

    @product.update(stock_count: new_stock)

    Request.create!(
      user: current_user,
      product: @product,
      quantity_change: quantity,
      status: :approved,
      allow_positive_quantity: true,
      organization_id: current_organization.id
    )

    redirect_to @product, notice: t('stock_updated_successfully')
  end

  def destroy
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