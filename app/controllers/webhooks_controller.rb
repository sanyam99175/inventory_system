class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']

    event = Stripe::Webhook.construct_event(
      payload,
      sig_header,
      Rails.application.credentials.dig(:stripe, :webhook_secret)
    )
    stripe_now = Time.at(event.created)

    case event.type

    # ✅ Checkout completed → create/update subscription
    when "checkout.session.completed"
      handle_checkout(event.data.object)

    # ✅ Subscription created/updated (covers trialing → active)
    when "customer.subscription.created",
         "customer.subscription.updated"
      handle_subscription(event.data.object)

    # ✅ Payment success
    when "invoice.payment_succeeded"
      handle_payment_success(event.data.object)

    # ❌ Payment failed
    when "invoice.payment_failed"
      handle_payment_failed(event.data.object)

    # ❌ Subscription canceled
    when "customer.subscription.deleted"
      handle_subscription_canceled(event.data.object)

    end

    head :ok

  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.error "Stripe Webhook Error: #{e.message}"
    head :bad_request
  end

  private

  # 🔥 Checkout completed
  def handle_checkout(session)
    return unless session.mode == "subscription"

    org = Organization.find_by(stripe_customer_id: session.customer)
    return unless org

    subscription = Stripe::Subscription.retrieve(session.subscription)

    org.update!(
      stripe_subscription_id: subscription.id,
      subscription_status: subscription.status,
      trial_ends_at: subscription.trial_end ? Time.at(subscription.trial_end) : nil,
      plan: map_plan(subscription),
      trial_used: true 
    )

    customer_id = session.customer

    payment_method = session.payment_intent
    pi = Stripe::PaymentIntent.retrieve(payment_method)

    Stripe::Customer.update(
        customer_id,
        invoice_settings: {
        default_payment_method: pi.payment_method
        }
    )

    broadcast_plan_update(org)
  end

  # 🔄 Subscription created/updated
  def handle_subscription(subscription)
    org = Organization.find_by(stripe_customer_id: subscription.customer)
    return unless org

    org.update!(
      stripe_subscription_id: subscription.id,
      subscription_status: subscription.status,
      trial_ends_at: subscription.trial_end ? Time.at(subscription.trial_end) : nil,
      plan: map_plan(subscription),
      stripe_now: stripe_now 
    )

    broadcast_plan_update(org)
  end

  # ✅ Payment success → active
  def handle_payment_success(invoice)
    org = Organization.find_by(stripe_customer_id: invoice.customer)
    return unless org

    org.update!(subscription_status: "active")
  end

  # ❌ Payment failed → past_due
  def handle_payment_failed(invoice)
    org = Organization.find_by(stripe_customer_id: invoice.customer)
    return unless org

    org.update!(subscription_status: "past_due")
  end

  # ❌ Subscription canceled
  def handle_subscription_canceled(subscription)
    org = Organization.find_by(stripe_customer_id: subscription.customer)
    return unless org

    org.update!(
      subscription_status: "canceled",
      plan: "free"
    )

    broadcast_plan_update(org)
  end

  # 🧠 Map Stripe price → plan
  def map_plan(subscription)
    price_id = subscription.items.data.first.price.id

    basic_id   = Rails.application.credentials.dig(:stripe, :basic_price_id)
    premium_id = Rails.application.credentials.dig(:stripe, :premium_price_id)

    return "basic" if price_id == basic_id
    return "premium" if price_id == premium_id

    "free"
  end

  # 🔥 Turbo broadcast (UI update)
  def broadcast_plan_update(org)
    Turbo::StreamsChannel.broadcast_replace_to(
      "org_#{org.id}",
      target: "plan_badge",
      partial: "shared/plan_badge",
      locals: { org: org }
    )
  end

  def broadcast_subscription_canceled(org)
    Turbo::StreamsChannel.broadcast_replace_to(
      "org_#{org.id}",
      target: "force_logout",
      partial: "shared/force_logout",
      locals: { org: org }
    )
  end
end