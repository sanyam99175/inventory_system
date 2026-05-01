class AuditsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_owner

  def index
    @start_date = parse_date(params[:start_date]) || 30.days.ago.to_date
    @end_date = parse_date(params[:end_date]) || Date.today

    if @start_date > @end_date
        @start_date, @end_date = @end_date, @start_date
    end

    page = params[:page].to_i
    page = 1 if page <= 0
    per_page = 10

    scope = current_organization.audit_logs
                .where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)
                .order(created_at: :desc)

    @total_count = scope.count
    @total_pages = (@total_count / per_page.to_f).ceil

    @audit_logs = scope
                    .offset((page - 1) * per_page)
                    .limit(per_page)

    @current_page = page
  end

  def show
    @audit_log = current_organization.audit_logs.find(params[:id])
    @performed_user = User.find_by(id: @audit_log.details["performed_for_user_id"])
  end

  def parse_date(date_string)
    Date.parse(date_string) if date_string.present?
  rescue ArgumentError
    nil
  end

  private

  def require_owner
    unless current_user.permission_enabled?("audits")
      redirect_to root_path, alert: t('access_denied_owners_only_audits')
    end
  end
end