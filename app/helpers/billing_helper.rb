# app/helpers/billing_helper.rb
module BillingHelper
  def price_for(plan)
    case plan
    when "basic"
      ENV['BASIC_PRICE_ID']
    when "premium"
      ENV['PREMIUM_PRICE_ID']
    end
  end
end