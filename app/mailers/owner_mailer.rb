class OwnerMailer < ApplicationMailer
  def history_pdf_email(user, requests, filters = {})
    @user = user
    @filters = filters.to_h

    pdf = HistoryPdf.new(requests, @filters).render

    attachments["stock-history.pdf"] = {
      mime_type: "application/pdf",
      content: pdf.force_encoding("BINARY")
     }

    mail(to: @user.email, subject: "Stock History Report")
  end
end
