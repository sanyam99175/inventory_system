class NotificationMailer < ApplicationMailer
    def low_stock_alert(user, product)
        @user = user
        @product = product

        mail(
        to: @user.email,
        subject: "⚠️ Low Stock Alert for #{@product.name}"
        )
    end

    def welcome_email(user)
        @user = user
        @dashboard_url = Rails.application.routes.url_helpers.dashboard_path(organization_id: @user.organization.id)
        mail(
        to: @user.email,
        subject: "Welcome to Inventory System, #{@user.name}!"
        )
    end
end
