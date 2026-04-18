class RecycleBinController < ApplicationController
  before_action :authenticate_user!
  before_action :require_worker

  def index
    @deleted_products = Product.only_deleted.order(deleted_at: :desc)
    @deleted_users = User.only_deleted.order(deleted_at: :desc)
  end

  def restore_product
    @product = Product.only_deleted.find(params[:id])
    if @product.recover
      AuditLog.create(
        record_type: 'Product',
        record_id: @product.id,
        action: 'restore',
        details: @product.name,
        user_id: current_user.id
      )
      redirect_to recycle_bin_path, notice: "Product '#{@product.name}' has been restored successfully."
    else
      redirect_to recycle_bin_path, alert: "Failed to restore product."
    end
  end

  def restore_user
    @user = User.only_deleted.find(params[:id])
    if @user.recover
      AuditLog.create(
        record_type: 'User',
        record_id: @user.id,
        action: 'restore',
        details: @user.email,
        user_id: current_user.id
      )
      redirect_to recycle_bin_path, notice: "User '#{@user.email}' has been restored successfully."
    else
      redirect_to recycle_bin_path, alert: "Failed to restore user."
    end
  end

  private

  def require_worker
    unless current_user.permission_enabled?("recycle_bin")
      redirect_to root_path, alert: "Access denied. Only owners can access the recycle bin."
    end
  end
end