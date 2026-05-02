class Organization < ApplicationRecord
  has_many :users, dependent: :delete_all
  has_many :products, dependent: :delete_all
  has_many :product_types, dependent: :delete_all
  has_many :requests, dependent: :delete_all
  has_many :notifications, dependent: :delete_all
  has_many :histories, dependent: :delete_all
  has_many :stock_requests, dependent: :delete_all
  has_many :audit_logs, dependent: :delete_all

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
      ENV['BASIC_PRICE_ID']
    when "premium"
      ENV['PREMIUM_PRICE_ID']
    end
  end

  def trial_used?
    trial_used == true
  end

  def trial_active?
    return false if trial_ends_at.blank?
    Time.current < trial_ends_at
  end

  def trial_expired?
    return false if trial_ends_at.blank?
    Time.current >= trial_ends_at
  end

  def access_allowed?
    return true if subscription_status == "active"
    return true if subscription_status == "trialing" && trial_active?

    false
  end

  def trialing?
    subscription_status == "trialing" || self.trial_days_left > 0
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
