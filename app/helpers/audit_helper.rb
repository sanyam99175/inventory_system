module AuditHelper
  # ========================
  # MAIN DIFF FORMATTER
  # ========================
  def format_diff_value(field, value)
    return "—" if value.blank?

    field = field.to_s

    case field
    # 🔹 Product type lookup
    when "product_type_id"
      product_type = ProductType.find_by(id: value)
      product_type&.name || "Unknown"

    # 🔥 HANDLE PERMISSIONS CLEANLY
    when "permissions"
      return format_permissions(value)

    else
      case value
      when TrueClass, FalseClass
        value ? "Yes" : "No"

      when Hash, Array
        # fallback (safe, readable)
        value.to_s

      else
        value.to_s
      end
    end
  end

  def permission_matrix(before, after)
    before ||= {}
    after  ||= {}

    all_modules = before.keys | after.keys

    # Collect all possible actions dynamically
    all_actions = (before.values + after.values).flatten.uniq

    {
        modules: all_modules,
        actions: all_actions.sort,
        before: before,
        after: after
    }
  end

  # ========================
  # PERMISSION FORMATTERS
  # ========================
  def format_permissions(value)
    return "—" unless value.is_a?(Hash)

    value.map do |module_name, actions|
      actions = Array(actions)
      next if actions.empty?

      "#{module_name.humanize}: #{actions.join(', ')}"
    end.compact.join(" | ")
  end

  # 🔥 DIFF (Used if you want smarter UI)
  def format_permission_diff(before, after)
    before ||= {}
    after  ||= {}

    all_keys = before.keys | after.keys

    all_keys.map do |key|
      b = Array(before[key])
      a = Array(after[key])

      added   = a - b
      removed = b - a

      next if added.empty? && removed.empty?

      result = "#{key.humanize}: "
      result += "➕ #{added.join(', ')} " if added.any?
      result += "➖ #{removed.join(', ')}" if removed.any?

      result.strip
    end.compact.join(" | ")
  end

  # ========================
  # TIMELINE HELPERS
  # ========================
  def resource_name(log)
    log.record_type.to_s.underscore.humanize
  end

  def timeline_title(log)
    details = log.details.is_a?(Hash) ? log.details : {}
    source  = details.dig("meta", "source")

    case log.action
    when "create"
        return "Request Created" if log.record_type == "Request"
        "#{resource_name(log)} created"

    when "approve_request"
        "Request Approved"

    when "reject_request"
        "Request Rejected"

    when "cancel_request"
        "Request Cancelled"

    when "update_stock"
        if source == "request_approval"
        "Stock Updated via Request Approval"
        else
        "Stock Updated"
        end

    when "permission_update"
        "Permissions Updated"

    when "destroy"
        "#{resource_name(log)} deleted"

    else
        "#{resource_name(log)} updated"
    end
  end

  def timeline_color(log)
    case log.action
    when "create" then "bg-blue-500"          # worker created
    when "approve_request" then "bg-green-500"
    when "reject_request" then "bg-red-500"
    when "cancel_request" then "bg-gray-500"
    when "update_stock" then "bg-yellow-500"
    when "permission_update" then "bg-purple-500"
    else "bg-blue-500"
    end
  end

  def timeline_subtext(log)
    details = log.details.is_a?(Hash) ? log.details : {}

    actor    = details.dig("meta", "performed_by_name") || log.actor_name
    product  = details.dig("meta", "product_name")
    source   = details.dig("meta", "source")
    requester = details.dig("meta", "requested_by")

    case log.action
    when "create"
        "Request created by #{actor}#{product ? " for #{product}" : ""}"

    when "approve_request"
        "Request approved by #{actor}#{product ? " for #{product}" : ""}"

    when "reject_request"
        "Request rejected by #{actor}#{product ? " for #{product}" : ""}"

    when "cancel_request"
        "Request cancelled by #{actor}#{product ? " for #{product}" : ""}"

    when "update_stock"
        if source == "request_approval"
        # 🔥 KEY DIFFERENTIATION
        "Stock updated after #{requester}'s request was approved by #{actor}#{product ? " for #{product}" : ""}"
        else
        "Stock directly updated by #{actor}#{product ? " for #{product}" : ""}"
        end

    when "permission_update"
        target = details.dig("meta", "performed_for_name")
        "#{actor} updated permissions for #{target}"

    else
        "#{actor} updated #{resource_name(log).downcase}"
    end
  end

  # ========================
  # MISC
  # ========================
  def format_quantity(qty)
    return "" unless qty
    qty.to_i > 0 ? "+#{qty}" : qty.to_s
  end
end