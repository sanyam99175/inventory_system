# app/controllers/subscriptions_controller.rb
class SubscriptionsController < ApplicationController
  def create
    org = current_organization

    StripeCustomerService.call(org, current_user)

    session = Stripe::Checkout::Session.create(
      customer: org.stripe_customer_id,
      mode: "subscription",
      payment_method_types: ["card"],
      line_items: [{
        price: params[:price_id],
        quantity: 1
      }],
      subscription_data: {
        trial_period_days: 7
      },
      success_url: success_url,
      cancel_url: pricing_url
    )

    redirect_to session.url, allow_other_host: true
  end

  private

  def success_url
    dashboard_url(subdomain: request.subdomain)
  end
end