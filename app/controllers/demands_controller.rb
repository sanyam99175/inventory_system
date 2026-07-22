class DemandsController < ApplicationController
  before_action :set_demand, only: [:show, :pdf, :execute]

  def new
    @demand = current_organization.demands.new
    @demand.demand_date = Date.today
    @demand.supplier_id = params[:supplier_id] if params[:supplier_id].present?
    @demand.demand_items.build(product_id: params[:product_id], quantity: params[:quantity]) if params[:product_id].present?
    @demand.demand_items.build if @demand.demand_items.empty?
  end

  def create
    @demand = current_organization.demands.new(demand_params)
    @demand.status = :generated

    if @demand.save
        redirect_to demands_path, notice: "Demand created successfully"
    else
        render :new, status: :unprocessable_entity
    end
  end

  def index
    @demands = current_organization.demands
                                    .includes(:purchase)
                                    .order(created_at: :desc)
  end

  # 👉 ONLY navigation step
  def execute
    redirect_to new_purchase_path(demand_id: @demand.id)
  end

  def pdf
    @demand = current_organization.demands.find(params[:id])

    html = render_to_string(
        template: "demands/pdf",
        layout: "pdf",
        formats: [:html]
    )

    pdf = Grover.new(html).to_pdf

    send_data pdf,
                filename: "demand_#{@demand.id}.pdf",
                type: "application/pdf",
                disposition: "inline"
  end

  private

  def set_demand
    @demand = current_organization.demands.find(params[:id])
  end

  def demand_params
    params.require(:demand).permit(
      :supplier_id,
      :demand_date,
      :notes,
      demand_items_attributes: [:id, :product_id, :quantity, :_destroy]
    )
  end
end