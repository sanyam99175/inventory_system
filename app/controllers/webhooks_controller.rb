class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    event = Stripe::Webhook.construct_event(
      payload,
      sig_header,
      ENV["WEBHOOK_SECRET_KEY"]
    )

    return head :ok if WebhookEvent.exists?(stripe_event_id: event.id)

    WebhookEvent.create!(
      stripe_event_id: event.id,
      event_type: event.type
    )

    case event.type
    when "checkout.session.completed"
      handle_checkout(event.data.object)

    when "customer.subscription.created",
         "customer.subscription.updated"
      handle_subscription(event.data.object)

    when "invoice.payment_succeeded"
      handle_payment_success(event.data.object)

    when "invoice.payment_failed"
      handle_payment_failed(event.data.object)

    when "customer.subscription.deleted"
      handle_subscription_canceled(event.data.object)
    end

    head :ok

  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.error "Stripe Webhook Error: #{e.message}"
    head :bad_request
  end

  private

  # ============================
  # CHECKOUT COMPLETED (PAID ONLY)
  # ============================
  def handle_checkout(session)
    return unless session.mode == "subscription"
    return unless session.subscription.present?

    org = Organization.find_by(stripe_customer_id: session.customer)
    return unless org

    subscription = Stripe::Subscription.retrieve(session.subscription)

    org.update!(
      stripe_subscription_id: subscription.id,
      subscription_status: "active",
      plan: map_plan(subscription)
    )

    broadcast_plan_update(org)
  end

  # ============================
  # SUBSCRIPTION SYNC (SOURCE OF TRUTH)
  # ============================
  def handle_subscription(subscription)
    org = Organization.find_by(stripe_customer_id: subscription.customer)
    return unless org

    org.update!(
      stripe_subscription_id: subscription.id,
      subscription_status: subscription.status, # active / past_due / canceled
      plan: map_plan(subscription)
    )

    broadcast_plan_update(org)
  end

  # ============================
  # PAYMENT SUCCESS
  # ============================
  def handle_payment_success(invoice)
    org = Organization.find_by(stripe_customer_id: invoice.customer)
    return unless org

    org.update!(subscription_status: "active")
  end

  # ============================
  # PAYMENT FAILED
  # ============================
  def handle_payment_failed(invoice)
    org = Organization.find_by(stripe_customer_id: invoice.customer)
    return unless org

    org.update!(subscription_status: "past_due")
  end

  # ============================
  # SUBSCRIPTION CANCELED
  # ============================
  def handle_subscription_canceled(subscription)
    org = Organization.find_by(stripe_customer_id: subscription.customer)
    return unless org

    org.update!(
      subscription_status: "canceled",
      plan: nil
    )

    broadcast_plan_update(org)
    broadcast_subscription_canceled(org)
  end

  # ============================
  # MAP PLAN FROM STRIPE
  # ============================
  def map_plan(subscription)
    price_id = subscription.items&.data&.first&.price&.id
    return nil unless price_id

    case price_id
    when ENV["BASIC_PRICE_ID"]
      "basic"
    when ENV["PREMIUM_PRICE_ID"]
      "premium"
    else
      nil
    end
  end

  # ============================
  # UI UPDATES
  # ============================
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