# app/services/stripe_customer_service.rb
class StripeCustomerService
  def self.call(org, user)
    return org.stripe_customer_id if org.stripe_customer_id.present?

    customer = Stripe::Customer.create(
      email: user.email,
      name: org.name
    )

    org.update!(stripe_customer_id: customer.id)
    customer.id
  end
end