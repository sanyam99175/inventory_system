class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def receive
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']

    event = Stripe::Webhook.construct_event(
      payload,
      sig_header,
      Rails.application.credentials.dig(:stripe, :webhook_secret)
    )

    case event.type
    when "customer.subscription.created",
         "customer.subscription.updated"
      handle_subscription(event.data.object)

    when "customer.subscription.deleted"
      handle_subscription_canceled(event.data.object)
    end

    render json: { ok: true }
  end

  private

  def handle_subscription(subscription)
    org = Organization.find_by(stripe_customer_id: subscription.customer)
    return unless org

    org.update!(
      stripe_subscription_id: subscription.id,
      plan: map_plan(subscription),
      subscription_status: subscription.status
    )


    Turbo::StreamsChannel.broadcast_replace_to(
        "org_#{org.id}",
        target: "plan_badge",
        partial: "shared/plan_badge",
        locals: { org: org }
    )
  end

  def handle_subscription_canceled(subscription)
    org = Organization.find_by(stripe_customer_id: subscription.customer)
    return unless org

    org.update!(
      plan: "free",
      subscription_status: "canceled"
    )
  end

  def map_plan(subscription)
    price_id = subscription.items.data.first.price.id

    basic_id   = Rails.application.credentials.dig(:stripe, :basic_price_id)
    premium_id = Rails.application.credentials.dig(:stripe, :premium_price_id)

    return "basic" if price_id == basic_id
    return "premium" if price_id == premium_id

    "free"
  end
end