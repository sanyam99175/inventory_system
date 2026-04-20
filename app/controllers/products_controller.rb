class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_view, only: [:index, :show]
  before_action :authorize_create_update, only: [:new, :create, :edit, :update, :update_stock]
  before_action :authorize_delete, only: [:destroy]
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  def index
    if params[:search].present?
      @products = Product.where("name ILIKE ?", "%#{params[:search]}%")
    else
      @products = Product.all
    end
  end

  def show
    @product = Product.find(params[:id])

    render 'show'
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to @product, notice: t('product_created_successfully')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @product = Product.find(params[:id])
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: t('product_updated_successfully')
    else
      render :edit
    end
  end

  def update_stock
    @product = Product.find(params[:id])
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
      allow_positive_quantity: true
    )
    redirect_to @product, notice: t('stock_updated_successfully')
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: t('product_deleted_successfully')
  end

  private

  def authorize_view
    redirect_to root_path, alert: t('not_authorized_view_products') unless current_user.has_permission?("products", "view")
  end

  def authorize_create_update
    redirect_to root_path, alert: t('not_authorized_modify_products') unless current_user.has_permission?("products", "create_update")
  end

  def authorize_delete
    redirect_to root_path, alert: t('not_authorized_delete_products') unless current_user.has_permission?("products", "delete")
  end

  def set_product
    @product = Product.find(params[:id])
  end

  def authorize_owner!
    redirect_to root_path, alert: t('not_authorized') unless current_user.owner?
  end

  def product_params
    params.require(:product).permit(:name, :stock_count, :godown_number, :alert_limit, :product_type_id)
  end
end