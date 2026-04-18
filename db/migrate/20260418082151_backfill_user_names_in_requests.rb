class BackfillUserNamesInRequests < ActiveRecord::Migration[7.1]
  def up
    Request.includes(:user).find_each do |request|
      if request.user
        request.update_column(:user_name, request.user.name.presence || request.user.email)
      end
    end
  end

  def down
    # No need to revert this data
  end
end
