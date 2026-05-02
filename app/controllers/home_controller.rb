class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :suspended]
  skip_before_action :set_current_organization, only: [:index]
  skip_before_action :check_subscription, only: [:index]
  skip_before_action :set_global_counts, only: [:index]

  def index
    if user_signed_in?
      org = current_user.organization

      if org
        @current_organization = org  
        redirect_to dashboard_path
      else
        render :index
      end
    else
      render :index
    end
  end

  def suspended
  end
end