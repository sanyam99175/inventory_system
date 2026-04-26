class Users::SessionsController < Devise::SessionsController

  def after_sign_in_path_for(resource)
    org = resource.organization

    if org
      dashboard_path(org_id: org.id)
    else
      root_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end