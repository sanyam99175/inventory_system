class AuditLogger
  IGNORED_FIELDS = %w[
    updated_at
    created_at
  ]

  def self.log(record:, action:, user:, organization:, changes: {}, meta: {})
    AuditLog.create!(
      record_type: record.class.name,
      record_id: record.id,
      action: action,
      user: user,
      organization: organization,
      details: build_details(record, action, changes, meta)
    )
  end

  # 🔥 Centralized details builder
  def self.build_details(record, action, changes, meta)
    cleaned = clean_attrs(record)

    case action
    when "create"
      {
        "after" => cleaned,
        "meta" => meta.merge(performed_by_name: meta[:performed_by_name])
      }

    when "destroy"
      {
        "before" => cleaned,
        "meta" => meta.merge(performed_by_name: meta[:performed_by_name])
      }

    else
      changes.merge("meta" => meta)
    end
  end

  # Helper for diff format
  def self.diff(before_hash, after_hash)
    diff = {}

    before_hash.each do |key, old_val|
      next if IGNORED_FIELDS.include?(key)

      new_val = after_hash[key]
      next if old_val == new_val

      diff[key] = {
        before: old_val,
        after: new_val
      }
    end

    diff
  end

  def self.clean_attrs(record)
    record.attributes.except(*IGNORED_FIELDS)
  end
end