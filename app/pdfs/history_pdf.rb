require "prawn"
require "prawn/table"

class HistoryPdf < Prawn::Document

  def initialize(requests, params = {})
    super(page_size: "A4", margin: 40)

    @requests = requests
    @params = normalize_params(params)

    header
    summary
    move_down 15
    table_content
  end

  # 🧾 HEADER
  def header
    text "TRAKLYN INVENTORY REPORT",
         size: 18,
         style: :bold,
         align: :center

    move_down 5

    text "Stock Movement History",
         size: 12,
         align: :center,
         color: "555555"

    move_down 10

    if @params[:start_date].present? && @params[:end_date].present?
      text "Period: #{@params[:start_date]} → #{@params[:end_date]}",
           size: 10,
           align: :center,
           color: "777777"
    end

    move_down 10
    stroke_horizontal_rule
    move_down 15
  end

  # 📊 SUMMARY
  def summary
    total = @requests.size

    approved_requests = @requests.select { |r| r.status == "approved" }

    incoming = approved_requests
      .select { |r| r.quantity_change.to_i > 0 }
      .sum { |r| r.quantity_change.to_i }

    outgoing = approved_requests
      .select { |r| r.quantity_change.to_i < 0 }
      .sum { |r| r.quantity_change.to_i.abs }

    approved = approved_requests.count
    rejected = @requests.count { |r| r.status == "rejected" }

    text "SUMMARY",
         style: :bold,
         size: 12

    move_down 8

    text "Total Transactions: #{total}"
    text "Items Added (IN): #{incoming}"
    text "Items Removed (OUT): #{outgoing}"
    text "Approved: #{approved} | Rejected: #{rejected}"

    move_down 10
    stroke_horizontal_rule
    move_down 10
  end

  # 📋 TABLE
  def table_content
    table(rows, header: true, width: bounds.width) do
      row(0).font_style = :bold
      row(0).background_color = "EEEEEE"

      self.cell_style = {
        padding: 6,
        size: 9
      }

      self.row_colors = ["FAFAFA", "FFFFFF"]
    end
  end

  def rows
    [["User", "Product", "Godown", "Qty", "Status", "Date"]] +
      @requests.map do |req|
        [
          req.user&.email || "-",
          req.product&.name || "-",
          req.product&.godown_number || "-",
          req.quantity_change.to_i,
          req.status.to_s.upcase,
          req.created_at.strftime("%d-%m-%Y %H:%M")
        ]
      end
  end


  def normalize_params(params)
    return {} if params.nil?

    if params.respond_to?(:permit)
      params.permit(:start_date, :end_date, :status, :user_id).to_h
    else
      params.slice(:start_date, :end_date, :status, :user_id)
    end
  end

end