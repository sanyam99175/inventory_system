class OrganizationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create]
  skip_before_action :set_current_organization
  skip_before_action :check_subscription, only: [:new, :create]
  skip_before_action :set_global_counts

  def new
    @organization = Organization.new
    @plan = params[:plan] || "free"
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
        customer = Stripe::Customer.create(
          email: user.email,
          name: @organization.name
        )

        @organization.update!(
          stripe_customer_id: customer.id,
          plan: @plan
        )

        sign_in(user)

        if @plan == "free"
          redirect_to dashboard_path(org_id: @organization.id)
        else
          redirect_to billing_checkout_path(
            org_id: @organization.id,
            price_id: price_id_for(@plan)
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

  def price_id_for(plan)
    case plan
    when "basic"
      Rails.application.credentials.dig(:stripe, :basic_price_id)
    when "premium"
      Rails.application.credentials.dig(:stripe, :premium_price_id)
    end
  end

  def organization_params
    params.require(:organization).permit(:name)
  end
end