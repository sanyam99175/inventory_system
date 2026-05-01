class Admin::DashboardController < Admin::BaseController
  def index
    @organizations = Organization.order(created_at: :desc)
  end
end