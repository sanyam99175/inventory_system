class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_view, only: [:index]
  before_action :authorize_create_update, only: [:new, :create]
  before_action :authorize_change_permissions, only: [:permissions, :update_permissions]
  before_action :authorize_delete, only: [:destroy]
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
    redirect_to users_path, notice: t('user_created_successfully')
        else
            flash.now[:alert] = @user.errors.full_messages.join(", ")
            render :new
        end
    end

  def permissions
    @permission_modules = User::PERMISSION_MODULES
  end

  def update_permissions
    permitted = params[:permissions] || {}

    new_permissions = {}

    User::PERMISSION_MODULES.each do |module_key, actions|
        selected = Array(permitted[module_key.to_s]).map(&:to_s)

        # ✅ enforce: if higher permission → include view
        if (selected - ["view"]).any? && !selected.include?("view")
        selected << "view"
        end

        new_permissions[module_key.to_s] = selected
    end

    @user.update(permissions: new_permissions)

    redirect_to users_path, notice: t('permissions_updated_successfully')
  end

  def destroy
    @user.destroy
    redirect_to users_path, notice: t('user_deleted_successfully')
  end

  private

  def authorize_view
    redirect_to root_path, alert: t('not_authorized_view_users') unless current_user.has_permission?("users", "view")
  end

  def authorize_create_update
    redirect_to root_path, alert: t('not_authorized_create_update_users') unless current_user.has_permission?("users", "create_update")
  end

  def authorize_change_permissions
    redirect_to root_path, alert: t('not_authorized_change_permissions') unless current_user.has_permission?("users", "change_permissions")
  end

  def authorize_delete
    redirect_to root_path, alert: t('not_authorized_delete_users') unless current_user.has_permission?("users", "delete")
  end

  def set_user
    @user = User.find(params[:id])
  end

  def authorize_owner!
    redirect_to root_path, alert: t('not_authorized') unless current_user.owner?
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end

  def format_permissions(permissions_hash)
    enabled_modules = permissions_hash.select do |k, v|
      if v.is_a?(Array)
        v.present?
      else
        !!v
      end
    end.keys
    enabled_modules.any? ? enabled_modules.join(', ') : 'none'
  end
end
