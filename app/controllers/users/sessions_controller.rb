class Users::SessionsController < Devise::SessionsController

  def after_sign_in_path_for(user)
    return admin_root_path if user.superadmin?

    org = user.organization

    return new_organization_path unless org

    if org.subscription_status == "incomplete"
      billing_checkout_path(plan: org.plan)
    else
      dashboard_path(organization_id: org.id)
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end