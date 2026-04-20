class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  def description
    case action
    when 'delete'
      I18n.t('audit.record_deleted', record_type: record_type, details: details)
    when 'restore'
      I18n.t('audit.record_restored', record_type: record_type, details: details)
    when 'create'
      I18n.t('audit.record_created', record_type: record_type, details: details)
    when 'update'
      I18n.t('audit.record_updated', record_type: record_type, details: details)
    when 'permission_update'
      details
    when 'approve_request'
      I18n.t('audit.request_approved', product: details)
    when 'reject_request'
      I18n.t('audit.request_rejected', product: details)
    when 'cancel_request'
      I18n.t('audit.request_cancelled', product: details)
    else
      I18n.t('audit.generic_action', action: action, record_type: record_type, details: details)
    end
  end

  def actor_name
    user&.name.presence || user&.email || 'System'
  end
end
