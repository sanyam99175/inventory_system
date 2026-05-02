class SendWelcomeEmailJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    @user = User.find(user_id)
    @dashboard_url = Rails.application.routes.url_helpers.dashboard_path(organization_id: @user.organization.id)
    mail(
    to: @user.email,
    subject: "Welcome to Inventory System, #{@user.name}!"
    )
  end
end