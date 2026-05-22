class OwnerController < ApplicationController
  before_action :check_trends_access, only: [:trends]
  before_action :check_history_access, only: [:history]
  before_action :check_requests_access, only: [:pending_requests]
  before_action :check_alerts_access, only: [:alerts]

  def check_trends_access
    unless PlanPermissions.allowed?(current_organization.plan, "trends")
      redirect_to upgrade_path(feature: "trends")
    end
  end

  def check_history_access
    unless PlanPermissions.allowed?(current_organization.plan, "history")
      redirect_to upgrade_path(feature: "history")
    end
  end

  def check_requests_access
    unless PlanPermissions.allowed?(current_organization.plan, "requests")
      redirect_to upgrade_path(feature: "requests")
    end
  end

  def check_alerts_access
    unless PlanPermissions.allowed?(current_organization.plan, "alerts")
      redirect_to upgrade_path(feature: "alerts")
    end
  end

  def dashboard
    @products = current_organization.products
    @requests = current_organization.requests.pending.order(created_at: :desc).limit(3)
    @pending_requests_count = current_organization.requests.pending.count
    @low_stock_products = current_organization.products.where("stock_count <= alert_limit")
  end

  def history
    @users = current_organization.users.select(:id, :email).order(:email)

    @requests = filtered_requests
                  .order(created_at: :desc)

    # ✅ pagination (safe check)
    @requests = @requests.page(params[:page]).per(5) if @requests.respond_to?(:page)

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
    requests = current_organization.requests.includes(:user, :product).order(created_at: :desc)

    if params[:start_date].present?
      start_date = Time.zone.parse(params[:start_date]).beginning_of_day
      requests = requests.where("created_at >= ?", start_date)
    end

    if params[:end_date].present?
      end_date = Time.zone.parse(params[:end_date]).end_of_day
      requests = requests.where("created_at <= ?", end_date)
    end

    requests = requests.where(status: params[:status]) if params[:status].present?
    requests = requests.where(user_id: params[:user_id]) if params[:user_id].present?

    requests
  end

  def send_history_pdf_email
    filters = params.permit(:start_date, :end_date, :status, :user_id).to_h

    requests = current_organization.requests.includes(:user, :product).order(created_at: :desc)

    if filters["start_date"].present?
      start_date = Time.zone.parse(filters["start_date"]).beginning_of_day
      requests = requests.where("created_at >= ?", start_date)
    end

    if filters["end_date"].present?
      end_date = Time.zone.parse(filters["end_date"]).end_of_day
      requests = requests.where("created_at <= ?", end_date)
    end

    requests = requests.where(status: filters["status"]) if filters["status"].present?
    requests = requests.where(user_id: filters["user_id"]) if filters["user_id"].present?

    owners = current_organization.users.owner

    owners.each do |owner|
      email = NotificationMailer.new.history_pdf_email(owner.id, requests.pluck(:id), filters)
      EmailSender.send_with_retry(
        to: owner.email,
        subject: email[:subject],
        html: email[:html],
        text: email[:text]
      )
    end

    redirect_to history_path(filters),
                notice: t("pdf_sent_successfully")
  end

  def pending_requests
    @requests = current_organization.requests.pending.order(created_at: :desc)
  end

  def alerts
    @products = current_organization.products.where("stock_count <= alert_limit")
  end

  def trends
    requests = current_organization.requests.where(status: :approved)

    # ================= DAILY TREND =================
    @daily_trends = requests
      .where("quantity_change < 0")
      .group("DATE(created_at)")
      .sum("ABS(quantity_change)")

    # ================= MONTHLY TREND =================
    @monthly_trends = requests
      .where("quantity_change < 0")
      .group("DATE_TRUNC('month', created_at)")
      .sum("ABS(quantity_change)")

    # ================= WEEKDAY =================
    weekday_raw = requests
      .where("quantity_change < 0")
      .group("EXTRACT(DOW FROM created_at)")
      .sum("ABS(quantity_change)")

    @weekday_trends = (0..6).map { |i| weekday_raw[i.to_f] || 0 }

    # ================= PRODUCT =================
    @product_trends = requests
      .joins(:product)
      .group("products.name")
      .sum("ABS(quantity_change)")
      .sort_by { |_, v| -v }
      .first(7)
      .to_h

    # ================= FIXED LOW STOCK ALERTS =================
    low_stock = current_organization.products.where("stock_count <= alert_limit")

    @alert_trends = low_stock
      .group("DATE(updated_at)")   # 🔥 FIX: use updated_at instead of created_at
      .count

    # ensure string-safe keys for Chart.js
    @alert_trends = @alert_trends.transform_keys { |k| k.to_date.strftime("%d %b") }

    # ================= FIXED USER ACTIVITY =================
    @user_trends = requests
      .joins(:user)
      .group("users.id", "users.name", "users.email")
      .sum("ABS(quantity_change)")
      .map do |(id, name, email), value|
        [name.presence || email, value]
      end
      .sort_by { |_, v| -v }
      .first(7)
      .to_h

    # ================= KPI =================
    all_values = @daily_trends.values

    @total_items_out = all_values.sum
    @daily_avg = all_values.any? ? (all_values.sum.to_f / all_values.size).round(2) : 0

    @peak_day = @daily_trends.max_by { |_, v| v }&.first
    @peak_day = @peak_day.is_a?(Date) ? @peak_day.strftime("%d %b") : @peak_day
    @show_early_stage_warning =
      current_organization.created_at > 30.days.ago ||
      current_organization.requests.count < 100
  end

  def time_range(range)
    case range
    when "week"
      [Date.current.beginning_of_week, Date.current.end_of_week]
    when "year"
      [Date.current.beginning_of_year, Date.current.end_of_year]
    when "custom"
      [
        params[:start_date].presence || Date.current.beginning_of_month,
        params[:end_date].presence || Date.current.end_of_month
      ]
    else
      [Date.current.beginning_of_month, Date.current.end_of_month]
    end
  end

  def previous_time_range(range)
    case range
    when "week"
      [1.week.ago.beginning_of_week, 1.week.ago.end_of_week]
    when "year"
      [1.year.ago.beginning_of_year, 1.year.ago.end_of_year]
    else
      [1.month.ago.beginning_of_month, 1.month.ago.end_of_month]
    end
  end

  def percentage_change(current, previous)
    return 0 if previous.to_f.zero?
    ((current.to_f - previous.to_f) / previous.to_f) * 100
  end

  def intelligence
    @range = (params[:range] || "month")

    start_date, end_date = time_range(@range)
    prev_start, prev_end = previous_time_range(@range)

    current = current_organization.requests.where(created_at: start_date..end_date)
    previous = current_organization.requests.where(created_at: prev_start..prev_end)

    # ================= CORE KPIs =================
    @total_activity = current.sum("ABS(quantity_change)")
    @prev_total_activity = previous.sum("ABS(quantity_change)")
    @activity_change_pct = percentage_change(@total_activity, @prev_total_activity)

    @request_count = current.count
    @prev_request_count = previous.count
    @request_change_pct = percentage_change(@request_count, @prev_request_count)

    # ================= STAFF =================
    staff = current.joins(:user)
                  .where.not(users: { role: "owner" })
                  .group("users.id", "users.name", "users.email")
                  .sum("ABS(quantity_change)")

    @staff_leaderboard = staff.map do |(_, name, email), total|
      {
        name: name.presence || email.split("@").first,
        total: total.to_i
      }
    end.sort_by { |s| -s[:total] }

    @top_staff = @staff_leaderboard.first

    # ================= PRODUCTS =================
    product = current.joins(:product)
                    .group("products.name")
                    .sum("ABS(quantity_change)")

    @product_usage = product
    @top_product = product.max_by { |_, v| v }

    @least_used = product.min_by { |_, v| v }

    # ================= SPARKLINE DATA =================
    @daily_series = current.group_by_day(:created_at).sum("ABS(quantity_change)")
    @daily_prev   = previous.group_by_day(:created_at).sum("ABS(quantity_change)")

    # ================= HEALTH SCORE =================

    activity_score = 100 - ((@activity_change_pct.to_f.abs / 2).clamp(0, 100))

    top = @staff_leaderboard.first
    second = @staff_leaderboard.second

    staff_score =
      if top.nil? || second.nil?
        70
      else
        ratio = top[:total].to_f / second[:total]
        (100 - (ratio - 1) * 20).clamp(0, 100)
      end

    product_score =
      if @product_usage.present?
        total = @product_usage.values.sum.to_f
        top = @product_usage.values.max.to_f

        if total == 0
          50
        else
          concentration = top / total
          (100 - concentration * 100).clamp(0, 100)
        end
      else
        50
      end

    risk_score = (100 - (@low_usage_count.to_i * 10)).clamp(0, 100)

    @health_score =
      (
        activity_score * 0.30 +
        staff_score * 0.25 +
        product_score * 0.25 +
        risk_score * 0.20
      ).round(1)

    @score_components = {
        activity: activity_score,
        staff: staff_score,
        product: product_score,
        risk: risk_score
      }

    @health_insights = build_health_insights(@score_components)
    @health_breakdown =
      health_score_breakdown(current, previous, staff, product)

    # ================= INSIGHTS =================
    @show_early_stage_warning =
      current_organization.created_at > 30.days.ago ||
      current_organization.requests.count < 100
    @insights = build_insights(@activity_change_pct, @top_staff, @top_product, @least_used)
  end

  def health_score_breakdown(current, previous, staff, product_usage)
    breakdown = {}

    # ================= ACTIVITY CHANGE =================
    current_activity = current.sum("ABS(quantity_change)")
    previous_activity = previous.sum("ABS(quantity_change)")

    activity_delta = current_activity - previous_activity

    breakdown[:activity] = {
      current: current_activity,
      previous: previous_activity,
      change: activity_delta,
      change_pct: percentage_change(current_activity, previous_activity)
    }

    # ================= STAFF IMPACT =================
    staff_sorted = staff.sort_by { |_, v| -v }

    top_staff = staff_sorted.first
    worst_staff = staff_sorted.last

    breakdown[:staff] = {
      top: { name: top_staff&.first&.dig(1), value: top_staff&.last },
      overloaded: top_staff,
      low: worst_staff
    }

    # ================= PRODUCT DEPENDENCY =================
    sorted_products = product_usage.sort_by { |_, v| -v }

    breakdown[:product] = {
      top: sorted_products.first,
      second: sorted_products.second,
      concentration: (sorted_products.first&.last.to_f / product_usage.values.sum).round(2)
    }

    # ================= RISK SIGNALS =================
    breakdown[:risk] = {
      low_usage_count: product_usage.count { |_, v| v < 5 },
      inactive_products: product_usage.select { |_, v| v == 0 }.keys
    }

    breakdown
  end

  def build_insights(activity_change, top_staff, top_product, least_used)
    insights = []

    insights << if activity_change > 25
      { type: "positive", text: "Activity is up #{activity_change.round(1)}% vs last period 🚀" }
    elsif activity_change < -20
      { type: "danger", text: "Activity dropped #{activity_change.abs.round(1)}% ⚠️" }
    else
      { type: "neutral", text: "Stable inventory movement 📊" }
    end

    insights << { type: "info", text: "Top staff: #{top_staff&.dig(:name)}" } if top_staff
    insights << { type: "info", text: "Top product: #{top_product&.first}" } if top_product
    insights << { type: "warning", text: "Low usage: #{least_used&.first}" } if least_used

    insights
  end

  def build_health_insights(score_components)
    insights = []

    # ACTIVITY
    if score_components[:activity] < 60
      insights << {
        type: :warning,
        title: "Low Activity",
        message: "Inventory movement is slower than normal. Stock may be idle.",
        impact: "High impact on sales flow"
      }
    elsif score_components[:activity] > 85
      insights << {
        type: :positive,
        title: "Strong Demand",
        message: "High inventory movement detected. Products are selling fast.",
        impact: "Good growth signal"
      }
    end

    # STAFF IMBALANCE
    if score_components[:staff] < 60
      insights << {
        type: :warning,
        title: "Staff Imbalance",
        message: "Workload is uneven across staff members.",
        impact: "May affect efficiency"
      }
    end

    # PRODUCT CONCENTRATION
    if score_components[:product] < 60
      insights << {
        type: :warning,
        title: "Product Dependency Risk",
        message: "Few products dominate overall usage.",
        impact: "High risk if demand shifts"
      }
    end

    # RISK
    if score_components[:risk] < 50
      insights << {
        type: :danger,
        title: "Inactive Stock Detected",
        message: "Several products are underutilized or idle.",
        impact: "Capital is blocked"
      }
    end

    insights
  end

  def approve_all_requests
    requests = current_organization.requests.pending

    Request.transaction do
      requests.each do |req|
        req.update!(status: "approved")

        product = req.product
        product.update!(stock_count: product.stock_count + req.quantity_change)

        AuditLog.create(
          record_type: "Request",
          record_id: req.id,
          action: "approve_request",
          details: product.name,
          user_id: current_user.id,
          organization_id: current_organization.id
        )
      end
    end

    redirect_to pending_requests_path,
                notice: t('all_pending_requests_approved')
  end
end