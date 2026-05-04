class SendWelcomeEmailJob < ApplicationJob
  def perform(user_id)
    user = User.find(user_id)
    SendgridMailer.send_email(
      to: user.email,
      subject: "Welcome to Traklyn",
      content: "<h1>Welcome #{user.name}</h1><p>Your account is ready.</p>"
    )
  end
end