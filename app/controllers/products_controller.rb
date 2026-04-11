class ProductsController < ApplicationController
  before_action :authenticate_user!
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
      redirect_to @product, notice: "Product created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @product = Product.find(params[:id])
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Product updated successfully."
    else
      render :edit
    end
  end

  def update_stock
    @product = Product.find(params[:id])
    quantity = params[:quantity_change].to_i

    new_stock = @product.stock_count + quantity

    if new_stock < 0
      redirect_to @product, alert: "Stock cannot go below zero"
      return
    end

    @product.update(stock_count: new_stock)
    Request.create!(
      user: current_user,
      product: @product,
      quantity_change: quantity,
      status: :approved
    )
    redirect_to @product, notice: "Stock updated successfully"
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Product deleted successfully."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def authorize_owner!
    redirect_to root_path, alert: "Not authorized" unless current_user.owner?
  end

  def product_params
    params.require(:product).permit(:name, :stock_count, :godown_number, :alert_limit, :product_type_id)
  end
end