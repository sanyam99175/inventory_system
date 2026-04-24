class HomeController < ApplicationController
  def index
    if main_domain?
      render :index
      return
    end
    
    return unless user_signed_in?

    if current_user.owner?
      redirect_to owner_dashboard_path
    else
      redirect_to worker_dashboard_path
    end
  end
end