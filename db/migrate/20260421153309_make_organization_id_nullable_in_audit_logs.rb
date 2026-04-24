class MakeOrganizationIdNullableInAuditLogs < ActiveRecord::Migration[7.1]
  def change
    change_column_null :audit_logs, :organization_id, true
  end
end
