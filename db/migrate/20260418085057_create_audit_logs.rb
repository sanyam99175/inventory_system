class CreateAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_logs do |t|
      t.string :record_type
      t.integer :record_id
      t.string :action
      t.text :details
      t.integer :user_id

      t.timestamps
    end
  end
end
