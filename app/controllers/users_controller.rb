class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_owner!, except: :index
  before_action :set_user, only: %i[permissions update_permissions destroy]

  def index
    @users = User.order(:email)

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where("name ILIKE ? OR email ILIKE ?", search_term, search_term)
    end
  end
    def new
        @user = User.new
    end

    def create
        @user = User.new(user_params)

        if @user.save
            redirect_to users_path, notice: "User created successfully."
        else
            flash.now[:alert] = @user.errors.full_messages.join(", ")
            render :new
        end
    end

  def permissions
    @permission_modules = User::PERMISSION_MODULES
  end

  def update_permissions
    selected_keys = params[:permissions]&.keys || []
    new_permissions = User::PERMISSION_MODULES.keys.index_with do |key|
      selected_keys.include?(key)
    end

    @user.permissions = new_permissions

    if @user.save
      redirect_to users_path, notice: "Permissions updated successfully."
    else
      @permission_modules = User::PERMISSION_MODULES
      flash.now[:alert] = "Unable to update permissions."
      render :permissions
    end
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: "User deleted successfully."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_owner!
    redirect_to root_path, alert: "Not authorized" unless current_user.owner?
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end
end
