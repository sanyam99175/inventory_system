class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  def description
    case action
    when 'delete'
      "#{record_type} \"#{details}\" was deleted"
    when 'restore'
      "#{record_type} \"#{details}\" was restored"
    when 'create'
      "#{record_type} \"#{details}\" was created"
    when 'update'
      "#{record_type} \"#{details}\" was updated"
    when 'approve_request'
      "Request for product \"#{details}\" was approved"
    when 'reject_request'
      "Request for product \"#{details}\" was rejected"
    when 'cancel_request'
      "Request for product \"#{details}\" was cancelled"
    else
      "#{action} on #{record_type} \"#{details}\""
    end
  end

  def actor_name
    user&.name.presence || user&.email || 'System'
  end
end
