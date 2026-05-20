class NotificationMailer < ApplicationMailer
    def low_stock_alert(user, product)
        @user = user
        @product = product

        html = ApplicationController.render(
        template: "notification_mailer/low_stock_alert",
        formats: [:html],
        assigns: { user: @user, product: @product },
        layout: false
        )

        text = ApplicationController.render(
        template: "notification_mailer/low_stock_alert",
        formats: [:text],
        assigns: { user: @user, product: @product },
        layout: false
        )

        {
        subject: "Low Stock Alert",
        html: html,
        text: text
        }
    end

    def history_pdf_email(owner_id, request_ids, filters = {})
        owner = User.find(owner_id)
        filters = filters.to_h

        requests = Request.where(id: request_ids)

        pdf = HistoryPdf.new(requests, filters).render
        pdf = pdf.force_encoding("BINARY")

        raise "PDF generation failed" if pdf.blank?

        html = ApplicationController.render(
            template: "notification_mailer/history_pdf_email",
            formats: [:html],
            assigns: { owner: owner, requests: requests, filters: filters },
            layout: false
        )

        text = ApplicationController.render(
            template: "notification_mailer/history_pdf_email",
            formats: [:text],
            assigns: { owner: owner, filters: filters },
            layout: false
        )

        {
            to: owner.email,
            subject: "Stock History Report",
            html: html,
            text: text,
            attachments: [
            {
                content: Base64.strict_encode64(pdf),
                type: "application/pdf",
                filename: "stock-history.pdf",
                disposition: "attachment"
            }
            ]
        }
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
        subject: "Welcome to Traklyn 🚀",
        html: html,
        text: text
        }
    end
end
