class AuditsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_owner

  def index
    @start_date = parse_date(params[:start_date]) || 30.days.ago.to_date
    @end_date = parse_date(params[:end_date]) || Date.today
    
    if @start_date > @end_date
      @start_date, @end_date = @end_date, @start_date
    end

    @audit_logs = AuditLog.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
                           .order(created_at: :desc)
  end

  def parse_date(date_string)
    Date.parse(date_string) if date_string.present?
  rescue ArgumentError
    nil
  end

  private

  def require_owner
    unless current_user.permission_enabled?("audits")
      redirect_to root_path, alert: "Access denied. Only owners can view audit logs."
    end
  end
end