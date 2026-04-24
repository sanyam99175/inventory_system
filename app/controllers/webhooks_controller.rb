class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def receive
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']

    event = Stripe::Webhook.construct_event(
      payload, sig_header, Rails.application.credentials.dig(:stripe, :webhook_secret)
    )

    case event.type
    when "checkout.session.completed"
      session = event.data.object

      org = Organization.find_by(stripe_customer_id: session.customer)

      subscription = Stripe::Subscription.retrieve(session.subscription)

      org.update!(
        stripe_subscription_id: subscription.id,
        plan: map_plan(subscription),
        subscription_status: subscription.status
      )
    end

    render json: { status: :ok }
  end

  private

  def map_plan(subscription)
    price_id = subscription.items.data.first.price.id

    case price_id
    when "price_basic_id"
      "basic"
    when "price_premium_id"
      "premium"
    else
      "free"
    end
  end
end