class OrganizationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  skip_before_action :set_current_organization
  skip_before_action :check_subscription, only: [:new, :create]
  skip_before_action :set_global_counts

  # ----------------------------
  # NEW
  # ----------------------------
  def new
    @plan = params[:plan] || "free"

    # ✅ prevent duplicate org creation for same user
    if current_user&.organization.present?
      redirect_to after_org_path(current_user.organization)
      return
    end

    @organization = Organization.new
  end

  # ----------------------------
  # AFTER ORG PATH (FIXED)
  # ----------------------------
  def after_org_path(org)
    # only expired / unpaid / incomplete go to billing
    billing_checkout_path(
        organization_id: org.id,
        price_id: org.price_id_for(org.plan)
    )
  end

  # ----------------------------
  # CREATE
  # ----------------------------
  def create
    @plan = params[:plan] || "free"

    existing_user = User.find_by(email: params[:user_email])

    if existing_user
        if existing_user.organization.present? && existing_user.organization.subscription_status == "expired"
            redirect_to root_path, notice: "You have already used Trial version, please buy any plan to access"
        else
            flash[:alert] = "You can only create one organization per user. Please sign in instead."
            redirect_to new_user_session_path
            return
        end
    end

    @organization = Organization.new(organization_params)



    unless @organization.save
      render :new, status: :unprocessable_entity
      return
    end

    user = @organization.users.build(
      email: params[:user_email],
      password: params[:user_password],
      password_confirmation: params[:user_password_confirmation],
      role: "owner"
    )

    unless user.save
      # ❌ rollback org ONLY if user creation fails
      @organization.destroy
      render :new, status: :unprocessable_entity
      return
    end

    # ----------------------------
    # STRIPE CUSTOMER (safe for test + prod)
    # ----------------------------
    customer = Stripe::Customer.create(
      email: user.email,
      name: @organization.name
    )

    # ----------------------------
    # ORG INIT STATE (IMPORTANT FIX)
    # ----------------------------
    if @plan == "free_trial"
        @organization.update!(
        stripe_customer_id: customer.id,
        plan: "free_trial",
        subscription_status: "trialing",
        trial_ends_at: 7.days.from_now,
        trial_used: true
        )

        sign_in(user)

        redirect_to dashboard_path(organization_id: @organization.id),
                    notice: "Free trial started 🚀"

        return
    end

    # ----------------------------
    # 💳 PAID FLOW
    # ----------------------------
    @organization.update!(
        stripe_customer_id: customer.id,
        plan: @plan,
        subscription_status: "incomplete",
        trial_used: false
    )

    flash[:notice] =
        if @plan == "basic"
            "Welcome! Your Basic plan is activated 🎉"
        else
            "Welcome! Your premium plan is activated 🎉 Enjoy complete stock flow "
        end

    # ----------------------------
    # REDIRECT FLOW (FIXED LOGIC)
    # ----------------------------
    sign_in(user)
    redirect_to after_org_path(@organization)
  end

  private

  def organization_params
    params.require(:organization).permit(:name)
  end
end