class ExportsController < ApplicationController
  before_action :authenticate_user!

  def users
    @users = User.where.not(role: :superadmin)

    respond_to do |format|
      format.xlsx {
        response.headers[
          "Content-Disposition"
        ] = "attachment; filename=users_export.xlsx"
      }
    end
  end

  def products
    @products = Product.all

    respond_to do |format|
      format.xlsx {
        response.headers[
          "Content-Disposition"
        ] = "attachment; filename=products_export.xlsx"
      }
    end
  end
end