class AddOrganizationToAuditLogs < ActiveRecord::Migration[7.1]
  def change
    add_reference :audit_logs, :organization, null: false, foreign_key: true
  end
end
