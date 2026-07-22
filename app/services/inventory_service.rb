class InventoryService
  def self.apply_purchase(purchase)
    return unless purchase.present?

    ActiveRecord::Base.transaction do
      purchase.purchase_items.each do |item|
        product = item.product
        product.increment!(:stock_count, item.quantity.to_i)
      end
    end
  end
end