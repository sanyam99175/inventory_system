class StockMailerPreview < ActionMailer::Preview
  def low_stock_alert
    user = User.first
    product = Product.first

    NotificationMailer.low_stock_alert(user, product)
  end
end