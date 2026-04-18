class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_owner!, except: :index

  def index
    @users = User.order(:email)

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where("name ILIKE ? OR email ILIKE ?", search_term, search_term)
    end
  end


  def destroy
    @user = User.find(params[:id])
    @user.destroy
    redirect_to users_path, notice: "User deleted successfully."
  end

  private

  def authorize_owner!
    redirect_to root_path, alert: "Not authorized" unless current_user.owner?
  end
end
