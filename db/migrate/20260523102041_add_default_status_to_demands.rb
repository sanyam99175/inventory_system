class AddDefaultStatusToDemands < ActiveRecord::Migration[7.1]
  def change
    change_column_default :demands, :status, 0
  end
end
