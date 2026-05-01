class RecycleBinController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_view, only: [:index]
  before_action :authorize_restore, only: [:restore_product, :restore_user]

  def index
    # 🔢 params
    @product_page = params[:product_page].to_i > 0 ? params[:product_page].to_i : 1
    @user_page    = params[:user_page].to_i > 0 ? params[:user_page].to_i : 1
    per_page      = (params[:per_page] || 10).to_i

    # 🔍 base scopes
    products_scope = current_organization.products.only_deleted.includes(:product_type)
    users_scope    = current_organization.users.only_deleted

    # 🔎 search filters
    products_scope = products_scope.where("name ILIKE ?", "%#{params[:product_search]}%") if params[:product_search].present?
    users_scope    = users_scope.where("email ILIKE ?", "%#{params[:user_search]}%") if params[:user_search].present?

    # 📊 counts
    @total_products = products_scope.count
    @total_users    = users_scope.count

    # 📄 pagination
    @deleted_products = paginate(products_scope.order(deleted_at: :desc), @product_page, per_page)
    @deleted_users    = paginate(users_scope.order(deleted_at: :desc), @user_page, per_page)

    # 📄 total pages
    @product_total_pages = total_pages(@total_products, per_page)
    @user_total_pages    = total_pages(@total_users, per_page)
  end

  def restore_product
    product = current_organization.products.only_deleted.find(params[:id])

    if product.recover
      log_audit(product, "restore")

      redirect_to recycle_bin_path,
        notice: t('product_restored_successfully', name: product.name)
    else
      redirect_to recycle_bin_path,
        alert: t('failed_restore_product')
    end
  end

  def restore_user
    user = current_organization.users.only_deleted.find(params[:id])

    if user.recover
      log_audit(user, "restore")

      redirect_to recycle_bin_path,
        notice: t('user_restored_successfully', email: user.email)
    else
      redirect_to recycle_bin_path,
        alert: t('failed_restore_user')
    end
  end

  private

  # 🔁 reusable pagination
  def paginate(scope, page, per_page)
    scope.offset((page - 1) * per_page).limit(per_page)
  end

  def total_pages(total_count, per_page)
    (total_count / per_page.to_f).ceil
  end

  def log_audit(record, action)
    AuditLog.create(
      record_type: record.class.name,
      record_id: record.id,
      action: action,
      user_id: current_user.id,
      organization_id: current_organization.id,
      details: build_metadata(record, action) # 👈 use details instead
    )
  end

  def build_metadata(record, action)
    {
      action: action,
      restored_at: Time.current,
      previous_deleted_at: record.deleted_at_before_last_save,
      record_snapshot: record.attributes.slice(
        "id",
        "name",
        "email",
        "stock_count",
        "role"
      ).compact
    }
  end

  # 🔐 permissions
  def authorize_view
    unless current_user.has_permission?("recycle_bin", "view")
      redirect_to root_path, alert: t('not_authorized_view_recycle_bin')
    end
  end

  def authorize_restore
    unless current_user.has_permission?("recycle_bin", "restore")
      redirect_to root_path, alert: t('not_authorized_restore_items')
    end
  end
end