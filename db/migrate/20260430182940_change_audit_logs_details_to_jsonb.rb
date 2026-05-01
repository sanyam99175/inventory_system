class ChangeAuditLogsDetailsToJsonb < ActiveRecord::Migration[7.1]
  def change
    # Convert invalid text to empty JSON
    execute <<-SQL
      UPDATE audit_logs
      SET details = '{}'
      WHERE details IS NULL OR details !~ '^{';
    SQL

    change_column :audit_logs, :details, :jsonb, using: 'details::jsonb'
  end

  def down
    change_column :audit_logs, :details, :text
  end
end
