class RecycleBinController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_view, only: [:index]
  before_action :authorize_restore, only: [:restore_product, :restore_user]

  def index
    @deleted_products = current_organization.products.only_deleted.order(deleted_at: :desc)
    @deleted_users = current_organization.users.only_deleted.order(deleted_at: :desc)
  end

  def restore_product
    @product = current_organization.products.only_deleted.find(params[:id])
    if @product.recover
      AuditLog.create(
        record_type: 'Product',
        record_id: @product.id,
        action: 'restore',
        details: @product.name,
        user_id: current_user.id,
        organization_id: current_organization.id
      )
      redirect_to recycle_bin_path, notice: t('product_restored_successfully', name: @product.name)
    else
      redirect_to recycle_bin_path, alert: t('failed_restore_product')
    end
  end

  def restore_user
    @user = current_organization.users.only_deleted.find(params[:id])
    if @user.recover
      AuditLog.create(
        record_type: 'User',
        record_id: @user.id,
        action: 'restore',
        details: @user.email,
        user_id: current_user.id,
        organization_id: current_organization.id
      )
      redirect_to recycle_bin_path, notice: t('user_restored_successfully', email: @user.email)
    else
      redirect_to recycle_bin_path, alert: t('failed_restore_user')
    end
  end

  private

  def authorize_view
    redirect_to root_path, alert: t('not_authorized_view_recycle_bin') unless current_user.has_permission?("recycle_bin", "view")
  end

  def authorize_restore
    redirect_to root_path, alert: t('not_authorized_restore_items') unless current_user.has_permission?("recycle_bin", "restore")
  end

  def require_worker
    unless current_user.permission_enabled?("recycle_bin")
      redirect_to root_path, alert: t('access_denied_owners_only_recycle_bin')
    end
  end
end