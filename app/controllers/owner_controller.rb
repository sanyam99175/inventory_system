class OwnerController < ApplicationController
  before_action :authenticate_user!

def dashboard
  @products = Product.all
  @requests = Request.pending.order(created_at: :desc).limit(3)
  @low_stock_products = Product.where("stock_count <= alert_limit")
end

  def history
    @users = User.select(:id, :email).order(:email)
    @requests = filtered_requests

    respond_to do |format|
      format.html

      format.pdf do
        pdf = HistoryPdf.new(@requests, params)

        send_data pdf.render,
                  filename: build_pdf_filename,
                  type: "application/pdf",
                  disposition: "attachment"
      end
    end
  end

  def build_pdf_filename
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date]).strftime("%d-%m-%Y")
      end_date   = Date.parse(params[:end_date]).strftime("%d-%m-%Y")

      "stock-history_#{start_date}_to_#{end_date}.pdf"
    else
      "stock-history_#{Date.today.strftime("%d-%m-%Y")}.pdf"
    end
  end

  def filtered_requests
    requests = Request.includes(:user, :product).order(created_at: :desc)

    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date]).beginning_of_day
      end_date   = Date.parse(params[:end_date]).end_of_day

      requests = requests.where(created_at: start_date..end_date)
    end

    requests = requests.where(status: params[:status]) if params[:status].present?
    requests = requests.where(user_id: params[:user_id]) if params[:user_id].present?

    requests
  end

  def send_history_pdf_email
    filters = params.permit(:start_date, :end_date, :status, :user_id).to_h

    requests = Request.includes(:user, :product).order(created_at: :desc)

    if filters["start_date"].present? && filters["end_date"].present?
      start_date = Date.parse(filters["start_date"]).beginning_of_day
      end_date   = Date.parse(filters["end_date"]).end_of_day

      requests = requests.where(created_at: start_date..end_date)
    end

    requests = requests.where(status: filters["status"]) if filters["status"].present?
    requests = requests.where(user_id: filters["user_id"]) if filters["user_id"].present?

    pdf = HistoryPdf.new(requests, filters).render

    OwnerMailer.history_pdf_email(current_user, pdf, filters).deliver_now

    redirect_to owner_history_path(filters),
                notice: "PDF sent to your email successfully."
  end

  def pending_requests
    @requests = Request.pending.order(created_at: :desc)
  end

  def alerts
    @products = Product.where("stock_count <= alert_limit")
  end

  def trends
    # DAILY (items taken out)
    @daily_trends = Request
      .where(status: :approved)
      .where("quantity_change < 0")
      .group("DATE(created_at)")
      .sum("ABS(quantity_change)")

    # MONTHLY (items taken out)
    @monthly_trends = Request
                        .where("quantity_change < 0")
                        .group("DATE(created_at)")
                        .sum("ABS(quantity_change)")
  end

  def approve_all_requests
    requests = Request.pending

    Request.transaction do
      requests.each do |req|
        req.update!(status: "approved")

        # update stock logic (important if you already have it)
        product = req.product
        product.update!(stock_count: product.stock_count + req.quantity_change)
      end
    end

    redirect_to owner_pending_requests_path,
                notice: "All pending requests approved successfully."
  end
end