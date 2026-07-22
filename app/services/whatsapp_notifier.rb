# app/services/whatsapp_notifier.rb

class WhatsappNotifier
  include HTTParty

  base_uri "http://localhost:3001"

  def self.send_low_stock_alert(product)
    post(
      "/send-message",
      headers: {
        "Content-Type" => "application/json"
      },
      body: {
        chat: "Shonak Flat",
        message: <<~MSG
          ⚠️ LOW STOCK ALERT

          Product: #{product.name}
          Current Stock: #{product.stock_count}
          Alert Limit: #{product.alert_limit}

          Please restock soon.
        MSG
      }.to_json
    )
  end
end