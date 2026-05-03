require "sendgrid-ruby"

class SendgridClient
  include SendGrid

  def initialize
    @client = SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"])
  end

  def send_email(to:, subject:, html:, text:)
    from = Email.new(email: "notifications@stockflows.in")
    to = Email.new(email: to)

    content = [
      Content.new(type: "text/plain", value: text),
      Content.new(type: "text/html", value: html)
    ]

    mail = Mail.new
    mail.from = from
    mail.subject = subject
    mail.add_personalization(Personalization.new.tap { |p| p.add_to(to) })
    mail.add_content(content[0])
    mail.add_content(content[1])

    response = @client.client.mail._("send").post(request_body: mail.to_json)

    Rails.logger.info("[SendGrid] status=#{response.status_code}")

    response
  end
end