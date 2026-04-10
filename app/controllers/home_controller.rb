class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_user.owner?
      redirect_to owner_dashboard_path
    else
      redirect_to worker_dashboard_path
    end
  end
end