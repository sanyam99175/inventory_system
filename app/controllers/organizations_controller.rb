class OrganizationsController < ApplicationController
  skip_before_action :set_current_organization
  skip_before_action :authenticate_user_if_subdomain
  skip_before_action :set_global_counts

  def new
    @organization = Organization.new
    @plan = params[:plan] || "free"
  end

  def create
    @plan = params[:plan].presence || "free"
    @organization = Organization.new(organization_params)

    if @organization.save
        user = @organization.users.build(
        email: params[:user_email],
        password: params[:user_password],
        password_confirmation: params[:user_password_confirmation],
        role: 'owner'
        )

        if user.save
        # ✅ Create Stripe customer
        customer = Stripe::Customer.create(
            email: user.email,
            name: @organization.name
        )

        @organization.update!(
            stripe_customer_id: customer.id,
            plan: @plan
        )

        sign_in(user)
        # 🔥 PLAN-BASED REDIRECT
        case @plan
        when "free"
            redirect_to root_url(subdomain: @organization.subdomain),
                        allow_other_host: true,
                        notice: "Organization created successfully"

        when "basic"
            redirect_to billing_checkout_url(
            price_id: Rails.application.credentials.dig(:stripe, :basic_price_id),
            subdomain: @organization.subdomain,
            protocol: "http"
            ),
            allow_other_host: true
        
        when "premium"
            redirect_to billing_checkout_url(
            price_id: Rails.application.credentials.dig(:stripe, :premium_price_id),
            subdomain: @organization.subdomain,
            protocol: "http"
            ),
            allow_other_host: true

        else
            redirect_to root_url(subdomain: @organization.subdomain),
                        allow_other_host: true
        end

        else
        @organization.destroy
        @organization.errors.add(:base, user.errors.full_messages.join(', '))
        render :new, status: :unprocessable_entity
        end

    else
        render :new, status: :unprocessable_entity
    end
  end

  private

  def organization_params
    params.require(:organization).permit(:name, :subdomain)
  end
end