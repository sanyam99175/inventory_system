class NotificationMailer < ApplicationMailer
    def low_stock_alert(user, product)
        @user = user
        @product = product

        mail(
        to: @user.email,
        subject: "⚠️ Low Stock Alert for #{@product.name}"
        )
    end

    def welcome(user)
        @user = user

        html = ApplicationController.render(
        template: "notification_mailer/welcome",
        formats: [:html],
        assigns: { user: user },
        layout: false
        )

        text = ApplicationController.render(
        template: "notification_mailer/welcome",
        formats: [:text],
        assigns: { user: user },
        layout: false
        )

        {
        subject: "Welcome to StockFlow 🚀",
        html: html,
        text: text
        }
    end
end
