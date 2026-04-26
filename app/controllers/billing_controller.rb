class BillingController < ApplicationController
  skip_before_action :check_subscription, only: [:checkout]
  before_action :authenticate_user!

  def checkout
    price_id = params[:price_id]

    session = Stripe::Checkout::Session.create(
      payment_method_types: ['card'],
      mode: 'subscription',
      customer: current_organization.stripe_customer_id,
      line_items: [{
        price: price_id,
        quantity: 1
      }],
      success_url: billing_success_url,
      cancel_url: root_url(subdomain: nil)
    )

    redirect_to session.url, allow_other_host: true
  end

  def success
    redirect_to dashboard_path, notice: "Subscription activated"
  end

  def upgrade
    @feature = params[:feature]
    @plans = PlanPermissions.upgrade_options(current_organization.plan)
  end
end