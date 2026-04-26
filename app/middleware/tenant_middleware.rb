# app/middleware/tenant_middleware.rb
class TenantMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    subdomain = request.subdomains.first
    tenant = Organization.find_by(subdomain: subdomain)

    env["current_tenant"] = tenant

    @app.call(env)
  end
end