class ImportsController < ApplicationController
  before_action :authenticate_user!

  require "roo"

  def users
    file = params[:file]
    return redirect_back fallback_location: root_path, alert: "File missing" unless file

    xlsx = Roo::Excelx.new(file.path)
    sheet = xlsx.sheet(0)

    (2..sheet.last_row).each do |i|
      row = sheet.row(i)

      User.create!(
        name: row[0],
        email: row[1],
        password: "123456",
        role: row[2] || "user"
      )
    end

    redirect_back fallback_location: root_path, notice: "Users imported successfully"
  end

  def products
    file = params[:file]
    return redirect_back fallback_location: root_path, alert: "File missing" unless file

    xlsx = Roo::Excelx.new(file.path)
    sheet = xlsx.sheet(0)

    (2..sheet.last_row).each do |i|
      row = sheet.row(i)

      Product.create!(
        name: row[0],
        product_type_id: ProductType.where(name: row[1]).first.id,
        stock_count: row[2],
        godown_number: row[3],
        alert_limit: row[4],
        organization_id: current_organization.id
      )
    end

    redirect_back fallback_location: root_path, notice: "Products imported successfully"
  end

  def users_template
    @users = []

    respond_to do |format|
        format.xlsx
    end
  end

  def products_template
    @products = []

    respond_to do |format|
        format.xlsx
    end
  end
end