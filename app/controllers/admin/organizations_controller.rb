class Admin::OrganizationsController < Admin::BaseController
  before_action :set_org, only: [:show, :suspend, :activate, :destroy, :impersonate]

  def index
    @organizations = Organization.all
  end

  def show
  end

  def suspend
    @org.update!(account_status: "suspended")
    redirect_to admin_organization_path(@org), notice: "Org suspended"
  end

  def activate
    @org.update!(account_status: "active")
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

  def reset_data
    org = Organization.find(params[:id])

    ActiveRecord::Base.transaction do
      org.users.delete_all
      org.products.delete_all
      org.requests.delete_all
      org.audits.delete_all if org.respond_to?(:audits)
    end

    redirect_to admin_organization_path(org), notice: "Organization data reset successfully"
  end

  private

  def set_org
    @org = Organization.find(params[:id])
  end
end