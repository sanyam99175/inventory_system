class HomeController < ApplicationController
  def index
    if user_signed_in?
      if current_user.owner?
        redirect_to owner_dashboard_path
      else
        redirect_to worker_dashboard_path
      end
    else
      render :index
    end
  end
end