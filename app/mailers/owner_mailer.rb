class OwnerMailer < ApplicationMailer
    def history_pdf_email(user, pdf_data, filters = {})
    @user = user
    @filters = filters

    attachments["stock-history.pdf"] = pdf_data

    mail(
        to: @user.email,
        subject: "Stock History Report"
    )
    end
end