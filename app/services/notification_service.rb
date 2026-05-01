# app/services/notification_service.rb
class NotificationService
  def self.send_email(user, product)
    NotificationMailer.low_stock_alert(user, product).deliver_now
  end

  def self.send_whatsapp(user, product)
    return unless user.phone_number.present?

    message = "⚠️ Low Stock Alert\nProduct: #{product.name}\nStock: #{product.stock_count}"

    TwilioClient.messages.create(
      from: "whatsapp:+14155238886",
      to: "whatsapp:#{user.phone_number}",
      body: message
    )
  end
end