class OwnerMailer < ApplicationMailer
  def history_pdf_email(owner_id, request_ids, filters = {})
    @owner = User.find(owner_id)
    @filters = filters.to_h

    requests = Request.where(id: request_ids)

    pdf = HistoryPdf.new(requests, @filters).render

    attachments["stock-history.pdf"] = {
      mime_type: "application/pdf",
      content: pdf
    }

    mail(to: @owner.email, subject: "Stock History Report")
  end
end