class Users::SessionsController < Devise::SessionsController
  def create
    super do |user|
      subdomain = request.subdomains.first
      org = Organization.find_by(subdomain: subdomain)

      if subdomain.present? && (org.nil? || user.organization_id != org.id)
        sign_out user
        redirect_to new_user_session_url(subdomain: subdomain),
                    alert: "Invalid organization login"
        return
      end
    end
  end

  def destroy
    sign_out(current_user)

    redirect_to new_user_session_url(subdomain: request.subdomains.first),
                allow_other_host: true,
                notice: "Signed out successfully"
  end
end