class LowStockAlertJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    product = Product.find(product_id)
    return unless product

    org = product.organization
    return unless org

    # ✅ Only owners
    binding.pry
    owners = org.users.owner

    # ✅ preload preferences
    prefs = NotificationPreference
              .where(organization: org, user: owners)
              .index_by(&:user_id)

    owners.find_each do |user|
      pref = prefs[user.id]

      # ✅ single toggle check
      next unless pref&.low_stock_alert

      # ✅ avoid spam per user
      next if recently_sent?(product, user)

      # ✅ send email (only channel now)
      NotificationService.send_email(user, product)

      mark_sent(product, user)
    end
  end

  private

  def recently_sent?(product, user)
    Rails.cache.read("low_stock_#{product.id}_#{user.id}")
  end

  def mark_sent(product, user)
    Rails.cache.write(
      "low_stock_#{product.id}_#{user.id}",
      true,
      expires_in: 2.hours
    )
  end
end