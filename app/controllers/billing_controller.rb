class BillingController < ApplicationController
  skip_before_action :check_subscription, only: [:checkout]
  before_action :authenticate_user!
  before_action :set_org, only: [:show, :create_portal, :cancel_subscription]

  def portal
    session = Stripe::BillingPortal::Session.create(
      customer: current_organization.stripe_customer_id,
      return_url: dashboard_url
    )

    redirect_to session.url, allow_other_host: true
  end

  def change_plan
    org = current_organization
    new_plan = params[:plan]

    # 🚫 Prevent same plan switch
    if org.plan == new_plan
        return redirect_to billing_path, notice: "You are already on #{new_plan.capitalize} plan"
    end

    price_id = org.price_id_for(new_plan)

    # 🧠 CASE 1: FREE → start trial via Checkout
    if org.plan == "free" || org.stripe_subscription_id.blank?
        return redirect_to billing_checkout_path(price_id: price_id)
    end

    begin
        # 🧠 Fetch current subscription
        subscription = Stripe::Subscription.retrieve(org.stripe_subscription_id)

        current_item_id = subscription.items.data.first.id

        update_params = {
        items: [{
            id: current_item_id,
            price: price_id
        }]
        }

        # 🧠 CASE 2: Trial → preserve trial (NO charge)
        if org.subscription_status == "trialing" && org.trial_ends_at.present?
        update_params[:trial_end] = org.trial_ends_at.to_i
        update_params[:proration_behavior] = "none"

        # 🧠 CASE 3: Active → apply proration (charge immediately)
        else
        update_params[:proration_behavior] = "create_prorations"
        end

        # 🔥 Update subscription
        updated_subscription = Stripe::Subscription.update(
        subscription.id,
        update_params
        )

        # 🔄 Sync local DB immediately (don’t wait for webhook)
        org.update!(
        plan: new_plan,
        subscription_status: updated_subscription.status,
        trial_ends_at: updated_subscription.trial_end ? Time.at(updated_subscription.trial_end) : nil
        )

        redirect_to billing_path, notice: "Switched to #{new_plan.capitalize} plan successfully 🚀"

    rescue Stripe::StripeError => e
        Rails.logger.error "Stripe error while changing plan: #{e.message}"
        redirect_to billing_path, alert: "Something went wrong while updating plan. Please try again."
    end
  end

  def checkout
    price_id = params[:price_id]
    org = current_organization

    # 🧠 Decide trial end properly
    trial_end =
        if org.trial_ends_at.present? && org.trial_ends_at > Time.current
        org.trial_ends_at.to_i   # existing trial
        else
        7.days.from_now.to_i     # new trial
        end

    session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        mode: 'subscription',
        customer: org.stripe_customer_id,
        line_items: [{
        price: price_id,
        quantity: 1
        }],
        subscription_data: {
        trial_end: trial_end
        },
        payment_method_collection: 'always',

        # 🔥 THIS is important for UI clarity
        allow_promotion_codes: true,

        success_url: billing_success_url,
        cancel_url: root_url(subdomain: nil)
    )

    redirect_to session.url, allow_other_host: true
  end

  def success
    redirect_to dashboard_path, notice: "You're now on #{current_organization.plan.capitalize} plan 🚀"
  end

  def upgrade
    @feature = params[:feature]
    @plans = PlanPermissions.upgrade_options(current_organization.plan)
  end

  def show
    @subscription = fetch_subscription
  end

  def create_portal
    session = Stripe::BillingPortal::Session.create(
      customer: @org.stripe_customer_id,
      return_url: dashboard_url
    )

    redirect_to session.url, allow_other_host: true
  end

  def cancel_subscription
    return redirect_to billing_path, alert: "No subscription found" unless @org.stripe_subscription_id

    Stripe::Subscription.update(
      @org.stripe_subscription_id,
      cancel_at_period_end: true
    )

    @org.update(subscription_status: "canceling")

    redirect_to billing_path, notice: "Subscription will be canceled at period end."
  end

  private

  def set_org
    @org = current_organization
  end

  def fetch_subscription
    return unless @org.stripe_subscription_id

    Stripe::Subscription.retrieve(@org.stripe_subscription_id)
  end
end