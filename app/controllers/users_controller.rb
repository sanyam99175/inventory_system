class UsersController < ApplicationController
  skip_before_action :check_subscription, only: [:new, :create]

  before_action :authenticate_user!
  before_action :authorize_view, only: [:index]
  before_action :authorize_create_update, only: [:new, :create]
  before_action :authorize_change_permissions, only: [:permissions, :update_permissions]
  before_action :authorize_delete, only: [:destroy]
  before_action :set_user, only: %i[permissions update_permissions destroy]

  # ========================
  # INDEX
  # ========================
  def index
    @users = current_organization.users.order(:email)

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @users = @users.where("name ILIKE ? OR email ILIKE ?", search_term, search_term)
    end
  end

  # ========================
  # NEW / CREATE
  # ========================
  def new
    @user = current_organization.users.new
  end

  def create
    @user = current_organization.users.build(user_params)

    if @user.save
      log_user_audit(
        action: "create",
        target_user: @user,
        changes: build_create_changes(@user)
      )

      redirect_to staffs_path, notice: t('user_created_successfully')
    else
      flash.now[:alert] = @user.errors.full_messages.join(", ")
      render :new
    end
  end

  # ========================
  # PERMISSIONS
  # ========================
  def permissions
    allowed = PlanPermissions.allowed_modules(current_organization.plan)
    @permission_modules = allowed
  end

  def update_permissions
    permitted = params[:permissions] || {}
    allowed = PlanPermissions.allowed_modules(current_organization.plan)

    old_permissions = (@user.permissions || {}).deep_dup

    new_permissions = {}

    allowed.each do |module_key, actions|
      selected = Array(permitted[module_key.to_s]).map(&:to_s)

      # keep only allowed actions
      selected &= actions

      # enforce: if higher permission → include view
      if (selected - ["view"]).any? && !selected.include?("view")
        selected << "view"
      end

      new_permissions[module_key.to_s] = selected
    end

    @user.update(permissions: new_permissions)

    log_user_audit(
      action: "permission_update",
      target_user: @user,
      changes: build_permission_changes(old_permissions, new_permissions)
    )

    redirect_to staffs_path, notice: t('permissions_updated_successfully')
  end

  # ========================
  # DELETE
  # ========================
  def destroy
    snapshot = @user.attributes.slice("name", "email", "role")

    log_user_audit(
      action: "destroy",
      target_user: @user,
      changes: build_delete_changes(snapshot)
    )

    @user.destroy

    redirect_to staffs_path, notice: t('user_deleted_successfully')
  end

  private

  # ========================
  # 🔥 AUDIT LOGGER (CORE)
  # ========================
  def log_user_audit(action:, target_user:, changes:)
    AuditLog.create(
      record_type: "User",
      record_id: target_user.id,
      action: action,
      details: changes.merge(
        meta: {
          performed_by_id: current_user.id,
          performed_by_name: current_user.name || current_user.email,
          performed_for_user_id: target_user.id,
          performed_for_name: target_user.name || target_user.email
        }
      ),
      user_id: current_user.id,
      organization_id: current_user.organization.id
    )
  end

  # ========================
  # CHANGE BUILDERS
  # ========================

  def build_create_changes(user)
    {
      name: { before: nil, after: user.name },
      email: { before: nil, after: user.email },
      role: { before: nil, after: user.role }
    }
  end

  def build_delete_changes(snapshot)
    {
      name: { before: snapshot["name"], after: nil },
      email: { before: snapshot["email"], after: nil },
      role: { before: snapshot["role"], after: nil }
    }
  end

  # 🔥 THIS FIXES YOUR PROBLEM
  def build_permission_changes(before, after)
    {
      permissions: {
        before: normalize_permissions(before),
        after: normalize_permissions(after)
      }
    }
  end

  # Normalize for consistent UI rendering
  def normalize_permissions(perms)
    return {} unless perms.is_a?(Hash)

    perms.transform_values do |actions|
      Array(actions).map(&:to_s).sort
    end
  end

  # ========================
  # AUTHORIZATION
  # ========================
  def authorize_view
    unless current_user.has_permission?("users", "view")
      redirect_to root_path, alert: t('not_authorized_view_users')
    end
  end

  def authorize_create_update
    unless current_user.has_permission?("users", "create_update")
      redirect_to root_path, alert: t('not_authorized_create_update_users')
    end
  end

  def authorize_change_permissions
    unless current_user.has_permission?("users", "change_permissions")
      redirect_to root_path, alert: t('not_authorized_change_permissions')
    end
  end

  def authorize_delete
    unless current_user.has_permission?("users", "delete")
      redirect_to root_path, alert: t('not_authorized_delete_users')
    end
  end

  # ========================
  # SETTERS
  # ========================
  def set_user
    @user = current_organization.users.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role)
  end
end