class ExportsController < ApplicationController
  before_action :authenticate_user!

  def users
    @users = current_organization.users.where.not(role: :superadmin)

    respond_to do |format|
      format.xlsx {
        response.headers[
          "Content-Disposition"
        ] = "attachment; filename=users_export.xlsx"
      }
    end
  end

  def products
    @products = current_organization.products

    respond_to do |format|
      format.xlsx {
        response.headers[
          "Content-Disposition"
        ] = "attachment; filename=products_export.xlsx"
      }
    end
  end

  def suppliers
    @suppliers = current_organization.suppliers

    respond_to do |format|
      format.xlsx {
        response.headers[
          "Content-Disposition"
        ] = "attachment; filename=suppliers_export.xlsx"
      }
    end
  end
end