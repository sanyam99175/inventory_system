class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  skip_before_action :set_current_organization, only: [:index]
  skip_before_action :check_subscription, only: [:index]
  skip_before_action :set_global_counts, only: [:index]

  def index
    # If logged in → go to dashboard
    if user_signed_in?
      org = current_user.organization

      if org
        redirect_to dashboard_path(org_id: org.id)
      else
        render :index
      end
    else
      # Public landing page
      render :index
    end
  end
end