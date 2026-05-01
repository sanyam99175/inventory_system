class OrganizationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  skip_before_action :set_current_organization
  skip_before_action :check_subscription, only: [:new, :create]
  skip_before_action :set_global_counts

  def new
    @plan = params[:plan] || "free"
    if current_user&.organization.present?
        redirect_to after_org_path(current_user.organization)
        return
    end

    @organization = Organization.new
  end

  def after_org_path(org)
    if org.subscription_status == "incomplete"
        billing_checkout_path(plan: org.plan)
    else
        dashboard_path(organization_id: org.id)
    end
  end

  def create
    @plan = params[:plan] || "free"
    @organization = Organization.new(organization_params)

    if @organization.save
      user = @organization.users.build(
        email: params[:user_email],
        password: params[:user_password],
        password_confirmation: params[:user_password_confirmation],
        role: "owner"
      )

      if user.save
        # Stripe customer
        if Rails.env.development?
            test_clock_id = "clock_1TRDiOSi8OBCPlBWSSAVBh4f"
            customer = Stripe::Customer.create(
            email: user.email,
            name: @organization.name,
            test_clock: test_clock_id
            )
        else
            customer = Stripe::Customer.create(
            email: user.email,
            name: @organization.name
            )
        end
        @organization.update!(
          stripe_customer_id: customer.id,
          plan: @plan,
          subscription_status: @plan == "free" ? "active" : "incomplete",
          trial_ends_at: @plan == "free" ? nil : 7.days.from_now
        )

        sign_in(user)

        if @plan == "free"
          redirect_to dashboard_path(@organization), notice: "Organization created with free plan"
        else
          redirect_to billing_checkout_path(
            org_id: @organization.id,
            price_id: @organization.price_id_for(@plan)
          )
        end

      else
        @organization.destroy
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def organization_params
    params.require(:organization).permit(:name)
  end
end