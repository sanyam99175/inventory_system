# app/helpers/billing_helper.rb
module BillingHelper
  def price_for(plan)
    case plan
    when "basic"
      Rails.application.credentials.dig(:stripe, :basic_price_id)
    when "premium"
      Rails.application.credentials.dig(:stripe, :premium_price_id)
    end
  end
end