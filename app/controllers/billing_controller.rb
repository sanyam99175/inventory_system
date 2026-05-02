class BillingController < ApplicationController
  skip_before_action :check_subscription, only: [:checkout, :success]
  before_action :authenticate_user!
  before_action :set_org

  # ----------------------------
  # STRIPE CUSTOMER PORTAL
  # ----------------------------
  def create_portal
    return redirect_to dashboard_path, alert: "No customer found" unless @org.stripe_customer_id

    session = Stripe::BillingPortal::Session.create(
      customer: @org.stripe_customer_id,
      return_url: dashboard_url(organization_id: @org.id)
    )

    redirect_to session.url, allow_other_host: true
  end

  # ----------------------------
  # PLAN CHANGE
  # ----------------------------
  def change_plan
    new_plan = params[:plan] 

    return redirect_to billing_path, notice: "Already on this plan" if @org.plan == new_plan

    price_id = @org.price_id_for(new_plan)

    begin
      subscription = Stripe::Subscription.retrieve(@org.stripe_subscription_id)
      item_id = subscription.items.data.first.id

      params_to_update = {
        items: [{ id: item_id, price: price_id }],
        proration_behavior: "create_prorations"
      }

      updated = Stripe::Subscription.update(subscription.id, params_to_update)

      # IMPORTANT: only partial sync (webhook is source of truth)
      @org.update!(
        plan: new_plan,
        subscription_status: updated.status
      )

      redirect_to billing_path, notice: "Plan updated successfully 🚀"

    rescue Stripe::StripeError => e
      Rails.logger.error(e.message)
      redirect_to billing_path, alert: "Stripe error occurred"
    end
  end

  # ----------------------------
  # CHECKOUT SESSION (NEW SUBSCRIPTION)
  # ----------------------------
  def checkout
    price_id = params[:price_id]

    session_params = {
      payment_method_types: ["card"],
      mode: "subscription",
      customer: @org.stripe_customer_id,
      line_items: [{ price: price_id, quantity: 1 }],
      success_url: billing_success_url(organization_id: @org.id),
      cancel_url: dashboard_url(organization_id: @org.id),
      allow_promotion_codes: true
    }

    session = Stripe::Checkout::Session.create(session_params)

    redirect_to session.url, allow_other_host: true
  end

  # ----------------------------
  # SUCCESS PAGE (UI ONLY)
  # ----------------------------
  def success
    redirect_to dashboard_path(organization_id: @org.id),
                notice: "Plan Activated"
  end

  def upgrade
    @feature = params[:feature]
  end

  # ----------------------------
  # BILLING OVERVIEW
  # ----------------------------
  def show
    @subscription = fetch_subscription
  end

  # ----------------------------
  # CANCEL SUBSCRIPTION
  # ----------------------------
  def cancel_subscription
    return redirect_to billing_path, alert: "No subscription found" unless @org.stripe_subscription_id

    Stripe::Subscription.update(
      @org.stripe_subscription_id,
      cancel_at_period_end: true
    )

    @org.update(subscription_status: "canceling")

    redirect_to billing_path, notice: "Subscription will cancel at period end"
  end

  private

  def set_org
    @org = current_organization
    redirect_to root_path, alert: "No organization found" unless @org
  end

  def fetch_subscription
    return nil unless @org.stripe_subscription_id
    Stripe::Subscription.retrieve(@org.stripe_subscription_id)
  end
end