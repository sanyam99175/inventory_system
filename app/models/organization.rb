class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :product_types, dependent: :destroy
  has_many :requests, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :histories, dependent: :destroy
  has_many :stock_requests, dependent: :destroy
  has_many :audit_logs, dependent: :destroy

  validates :name, presence: true

  def can_use?(feature)
    case plan
    when "free"
      %w[products requests].include?(feature)
    when "basic"
      %w[products requests history trends].include?(feature)
    when "premium"
      true
    end
  end


  def price_id_for(plan)
    case plan
    when "basic"
      Rails.application.credentials.dig(:stripe, :basic_price_id)
    when "premium"
      Rails.application.credentials.dig(:stripe, :premium_price_id)
    end
  end

  def trialing?
    subscription_status == "trialing" || self.trial_days_left > 0
  end

  def active?
    subscription_status.in?(%w[trialing active])
  end

  def past_due?
    subscription_status == "past_due"
  end

  def canceled?
    subscription_status == "canceled"
  end

  def stripe_now
    return Time.current unless Rails.env.development?
    return Time.current unless stripe_customer_id

    customer = Stripe::Customer.retrieve(stripe_customer_id)
    return Time.current unless customer.test_clock

    clock = Stripe::TestHelpers::TestClock.retrieve(customer.test_clock)
    Time.zone.at(clock.frozen_time)
  end

  def trial_days_left
    return 0 unless trial_ends_at

    now = Rails.env.development? ? stripe_now : Time.current
    ((trial_ends_at - now) / 1.day).ceil
  end
end
