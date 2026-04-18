require "prawn"
require "prawn/table"

class HistoryPdf < Prawn::Document

  def initialize(requests, params = {})
    super(page_size: "A4")
    @requests = requests
    @params = params

    header
    summary
    move_down 15
    table_content
  end

  # 🧾 HEADER (Tally style)
  def header
    text "STOCKFLOW INVENTORY REPORT", size: 18, style: :bold, align: :center
    text "Stock Movement History", size: 12, align: :center
    move_down 10

    if @params[:start_date].present? && @params[:end_date].present?
      text "Period: #{@params[:start_date]} to #{@params[:end_date]}", size: 10, align: :center
    end

    stroke_horizontal_rule
    move_down 10
  end

  # 📊 SUMMARY BLOCK
  def summary
    total = @requests.count
    outgoing = @requests
      .select { |r| r.status == "approved" && r.quantity_change.to_i < 0 }
      .sum { |r| r.quantity_change.to_i.abs }
    incoming = @requests
      .select { |r| r.status == "approved" && r.quantity_change.to_i > 0 }
      .sum { |r| r.quantity_change.to_i }
    approved = @requests.count { |r| r.status == "approved" }
    rejected = @requests.count { |r| r.status == "rejected" }

    text "SUMMARY", style: :bold, size: 12
    move_down 5

    text "Total Transactions: #{total}"
    text "Total Items In: #{incoming}"
    text "Total Items Out: #{outgoing}"
    text "Approved: #{approved} | Rejected: #{rejected}"
  end

  # 📋 TABLE
  def table_content
    move_down 10

    table rows, header: true do
      row(0).font_style = :bold
      row(0).background_color = "DDDDDD"

      self.cell_style = {
        padding: 6,
        size: 9
      }

      self.row_colors = ["F9F9F9", "FFFFFF"]
    end
  end

  def rows
    [["User", "Product", "Godown", "Qty", "Status", "Date"]] +
      @requests.map do |req|
        [
          req.user.email,
          req.product.name,
          req.product.godown_number,
          req.quantity_change,
          req.status.to_s.upcase,
          req.created_at.strftime("%d-%m-%Y %H:%M")
        ]
      end
  end

end