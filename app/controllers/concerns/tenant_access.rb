# app/controllers/concerns/tenant_access.rb
module TenantAccess
  extend ActiveSupport::Concern

  def current_organization
    request.env["current_tenant"]
  end

  def tenant?
    current_organization.present?
  end
end