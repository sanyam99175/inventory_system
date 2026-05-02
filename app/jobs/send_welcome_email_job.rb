class SendWelcomeEmailJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)
    NotificationMailer.welcome_email(user).deliver_now
  end
end