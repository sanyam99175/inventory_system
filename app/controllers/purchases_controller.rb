class PurchasesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :set_purchase, only: [:show, :edit, :update, :destroy]

  # =========================
  # INDEX
  # =========================
  def index
    @purchases = @organization.purchases
                              .includes(:supplier, :user)
                              .order(created_at: :desc)

    # FILTERS
    if params[:supplier_id].present?
      @purchases = @purchases.where(supplier_id: params[:supplier_id])
    end

    if params[:status].present?
      @purchases = @purchases.where(status: params[:status])
    end

    if params[:start_date].present?
      @purchases = @purchases.where(
        "purchase_date >= ?",
        params[:start_date]
      )
    end

    if params[:end_date].present?
      @purchases = @purchases.where(
        "purchase_date <= ?",
        params[:end_date]
      )
    end

    @suppliers = @organization.suppliers
  end

  # =========================
  # SHOW
  # =========================
  def show
  end

  def mark_paid
    @purchase = @organization.purchases.find(params[:id])
    @purchase.update_columns(
    paid_amount: @purchase.total_amount,
    due_amount: 0,
    status: "paid"
    )
    redirect_to @purchase, notice: "Purchase marked as paid."
  end

  def partially_pay
    @purchase = @organization.purchases.find(params[:id])
    amount = params[:amount].to_f
    if amount <= 0 || amount > (@purchase.total_amount - @purchase.paid_amount)
      redirect_to @purchase, alert: "Invalid payment amount."
      return
    end
    if amount == (@purchase.total_amount - @purchase.paid_amount)
      @purchase.update_columns(
        paid_amount: @purchase.paid_amount + amount,
        due_amount: @purchase.due_amount - amount,
        status: "paid"
      )
    else
      @purchase.update_columns(
        paid_amount: @purchase.paid_amount + amount,
        due_amount: @purchase.due_amount - amount
      )
    end
    redirect_to @purchase, notice: "Purchase partially paid."
  end

  # =========================
  # NEW
  # =========================
  def new
    @purchase = @organization.purchases.new

    @suppliers = @organization.suppliers
    @products  = @organization.products

    if params[:demand_id]
      demand = @organization.demands.find(params[:demand_id])

      @purchase.supplier_id = demand.supplier_id
      @purchase.purchase_date = Date.today
      @purchase.demand = demand

      demand.demand_items.each do |item|
        @purchase.purchase_items.build(
          product_id: item.product_id,
          quantity: item.quantity,
          unit_price: item.product.last_purchase_price || 0
        )
      end
    else
      @purchase.purchase_items.build
    end

    load_form_data
  end

  # =========================
  # CREATE
  # =========================
  def create
    @purchase = @organization.purchases.new(purchase_params)
    @purchase.purchase_date ||= Date.today
    @purchase.user = current_user

    if @purchase.save
      handle_demand_conversion(@purchase, @purchase.demand)

      InventoryService.apply_purchase(@purchase)

      if params[:purchase][:invoice].present?
        @purchase.invoice.attach(params[:purchase][:invoice])
      end

      redirect_to @purchase, notice: "Purchase created successfully."
    else
      load_form_data
      flash.now[:alert] = "Failed to create purchase."
      render :new, status: :unprocessable_entity
    end
  end

  def handle_demand_conversion(purchase, demand)
    return unless demand
    return if demand.purchase_id.present?

    demand.update!(
      status: :executed,
      converted_at: Time.current,
      purchase_id: purchase.id
    )
  end

  # =========================
  # EDIT
  # =========================
  def edit
    load_form_data
  end

  # =========================
  # UPDATE
  # =========================
  def update
    if @purchase.update(purchase_params)
      redirect_to @purchase,
                  notice: "Purchase updated successfully."
    else
      load_form_data

      flash.now[:alert] = "Failed to update purchase."

      render :edit, status: :unprocessable_entity
    end
  end

  # =========================
  # DESTROY
  # =========================
  def destroy
    @purchase.destroy

    redirect_to purchases_path,
                notice: "Purchase deleted successfully."
  end

  private

  # =========================
  # SET ORGANIZATION
  # =========================
  def set_organization
    @organization = current_organization
  end

  # =========================
  # SET PURCHASE
  # =========================
  def set_purchase
    @purchase = @organization.purchases.find(params[:id])
  end

  # =========================
  # FORM DATA
  # =========================
  def load_form_data
    @suppliers = @organization.suppliers.order(:name)

    @products = @organization.products
                             .includes(:supplier)
                             .order(:name)
  end

  # =========================
  # STRONG PARAMS
  # =========================
  def purchase_params
    params.require(:purchase).permit(
      :supplier_id,
      :invoice_number,
      :purchase_date,
      :discount,
      :tax,
      :total_amount,
      :paid_amount,
      :notes,
      :invoice,
      :demand_id,
      purchase_items_attributes: [
        :id,
        :product_id,
        :quantity,
        :unit_price,
        :total_price,
        :_destroy
      ]
    )
  end
end