class PlanPermissions
  PLANS = {
    "basic" => {
      products: ["view", "create_update"],
      requests: ["view", "update"],
      alerts: ["view"],
      history: ["view"],
      users: ["view", "create_update"],
      manage_subscription: ["view"]
    },
    "premium" => {
      products: ["view", "create_update", "delete"],
      requests: ["view", "update"],
      alerts: ["view"],
      history: ["view"],
      trends: ["view"],
      intelligence: ["view"],
      users: ["view", "create_update", "delete", "change_permissions"],
      audits: ["view"],
      recycle_bin: ["view", "restore"],
      manage_subscription: ["view"]
    },
    "free_trial" => {
      products: ["view", "create_update", "delete"],
      requests: ["view", "update"],
      alerts: ["view"],
      history: ["view"],
      trends: ["view"],
      intelligence: ["view"],
      users: ["view", "create_update", "delete", "change_permissions"],
      audits: ["view"],
      recycle_bin: ["view", "restore"],
    }
  }

  def self.allowed_modules(plan)
    PLANS[plan] || {}
  end

  def self.allowed?(plan, mod)
    plan = plan.to_s.downcase
    mod = mod.to_sym

    allowed_modules(plan).keys.include?(mod)
  end

  def self.allowed_action?(plan, mod, action)
    plan = plan.to_s.downcase
    mod = mod.to_sym
    action = action.to_s

    allowed = allowed_modules(plan)[mod]
    return false unless allowed

    allowed.include?(action)
  end

  def self.upgrade_options(plan)
    case plan
    when "basic" then %w[premium]
    else []
    end
  end
end