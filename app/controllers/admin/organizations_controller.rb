class Admin::OrganizationsController < Admin::BaseController
  before_action :set_org, only: [:show, :suspend, :activate, :destroy, :impersonate]

  def index
    @organizations = Organization.all
  end

  def show
  end

  def suspend
    @org.update!(subscription_status: "suspended")
    redirect_to admin_organization_path(@org), notice: "Org suspended"
  end

  def activate
    @org.update!(subscription_status: "active")
    redirect_to admin_organization_path(@org), notice: "Org activated"
  end

  def destroy
    @org.destroy!
    redirect_to admin_organizations_path, notice: "Org deleted"
  end

  def impersonate
    session[:admin_user_id] = current_user.id
    session[:user_id] = @org.users.first.id # or owner

    redirect_to dashboard_url(subdomain: @org.subdomain)
  end

  private

  def set_org
    @org = Organization.find(params[:id])
  end
end