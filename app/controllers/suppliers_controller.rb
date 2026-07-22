class SuppliersController < ApplicationController
  before_action :set_organization
  before_action :set_supplier, only: [:show, :edit, :update, :destroy]

  def index
    @suppliers = @organization.suppliers.order(created_at: :desc)
  end

  def show
    @supplier = current_organization.suppliers.find(params[:id])

    @purchases =
        @supplier.purchases
                .includes(:purchase_items)
                .order(created_at: :desc)

    @recent_purchases =
        @purchases.limit(10)

    @total_purchase_amount =
        @purchases.sum(:total_amount)

    @total_paid_amount =
        @purchases.sum(:paid_amount)

    @total_due_amount =
        @purchases.sum(:due_amount)

    @products_bought =
        PurchaseItem
            .joins(:purchase, :product)
            .where(purchases: { supplier_id: @supplier.id })
            .group("products.id", "products.name")
            .pluck(
            "products.id",
            "products.name",
            "SUM(purchase_items.quantity)",
            "MAX(purchases.purchase_date)"
            )

    @payment_history =
        @supplier.supplier_payments
                .order(created_at: :desc)

    @monthly_spending =
        @supplier.purchases
                .unscope(:order)
                .group_by_month(:purchase_date, last: 6)
                .sum(:total_amount)
  end

  def new
    @supplier = @organization.suppliers.new
  end

  def create
    @supplier = @organization.suppliers.new(supplier_params)

    if @supplier.save
      redirect_to suppliers_path(@organization),
                  notice: "Supplier created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @supplier.update(supplier_params)
      redirect_to suppliers_path(@organization),
                  notice: "Supplier updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @supplier.destroy

    redirect_to suppliers_path(@organization),
                notice: "Supplier deleted successfully."
  end

  private

  def set_organization
    @organization = current_organization
  end

  def set_supplier
    @supplier = @organization.suppliers.find(params[:id])
  end

  def supplier_params
    params.require(:supplier).permit(
      :name,
      :phone,
      :email,
      :address
    )
  end
end