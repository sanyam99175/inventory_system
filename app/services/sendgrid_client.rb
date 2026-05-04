require "sendgrid-ruby"
require "base64"

class SendgridClient
  include SendGrid

  def initialize
    @client = SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"])
  end

  def send_email(to:, subject:, html:, text:, attachments: [])
    from = Email.new(email: "notifications@stockflows.in")
    to = Email.new(email: to)

    mail = Mail.new
    mail.from = from
    mail.subject = subject

    personalization = Personalization.new
    personalization.add_to(to)
    mail.add_personalization(personalization)

    mail.add_content(Content.new(type: "text/plain", value: text.to_s))
    mail.add_content(Content.new(type: "text/html", value: html.to_s))

    attachments.each do |att|
      mail.add_attachment(
        Attachment.new(
          content: Base64.strict_encode64(att[:content]),  # 🔥 IMPORTANT
          type: att[:mime_type] || "application/pdf",
          filename: att[:filename] || "file.pdf",
          disposition: "attachment"
        )
      )
    end

    response = @client.client.mail._("send").post(request_body: mail.to_json)

    Rails.logger.info("[SendGrid] status=#{response.status_code}")
    Rails.logger.info("[SendGrid] body=#{response.body}")

    response
  end
end