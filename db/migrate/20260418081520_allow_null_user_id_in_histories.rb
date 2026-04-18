class AllowNullUserIdInHistories < ActiveRecord::Migration[7.1]
  def change
    change_column_null :histories, :user_id, true
  end
end
