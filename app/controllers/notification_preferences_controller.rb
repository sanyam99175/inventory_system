class NotificationPreferencesController < ApplicationController
  before_action :ensure_owner!

  def ensure_owner!
    redirect_to root_path unless current_user.owner?
  end

  def update
    @preference = NotificationPreference.find_or_initialize_by(
      user: current_user,
      organization: current_organization
    )

    attrs = preference_params

    # ✅ Keep email in sync with toggle
    attrs[:email] = attrs[:low_stock_alert]

    if @preference.update(attrs)
      redirect_to request.referer || root_path, notice: "Updated!"
    else
      redirect_to request.referer || root_path, alert: "Failed to update"
    end
  end

  private

  def preference_params
    params.require(:notification_preference)
          .permit(:low_stock_alert)
  end
end