class PlanPermissions
  PLANS = {
    "free" => {
      products: ["view", "create_update"],
      requests: ["view", "update"],
    },
    "basic" => {
      products: ["view", "create_update"],
      requests: ["view", "update"],
      alerts: ["view"],
      history: ["view"],
      trends: ["view"]
    },
    "premium" => {
      products: ["view", "create_update", "delete"],
      requests: ["view", "update"],
      alerts: ["view"],
      history: ["view"],
      trends: ["view"],
      users: ["view", "create_update", "delete", "change_permissions"],
      audits: ["view"],
      recycle_bin: ["view", "restore"]
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

  def self.upgrade_options(plan)
    case plan
    when "free" then %w[basic premium]
    when "basic" then %w[premium]
    else []
    end
  end
end