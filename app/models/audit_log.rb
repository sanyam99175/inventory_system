class AuditLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :organization

  # If not using jsonb, keep serialize
  serialize :details, JSON unless columns_hash["details"].type == :jsonb

  def description
    case action
    when 'create'
      "Created #{record_type}"
    when 'update'
      "Updated #{record_type}"
    when 'delete'
      "Deleted #{record_type}"
    when 'update_stock'
        performer = details["performed_by_name"]
        target = details["performed_for_name"]

        if target.present? && performer != target
            "Stock updated by #{performer} on behalf of #{target}"
        else
            "Stock updated by #{performer}"
        end
    else
      "#{action.humanize} #{record_type}"
    end
  end

  def actor_name
    user&.name.presence || user&.email || 'System'
  end

  def changes_present?
    details.is_a?(Hash)
  end
end