module UpgradeHelper

  def feature_description(feature)
    {
      "trends" => "Analyze stock movement and demand patterns with powerful insights.",
      "audits" => "Track every action for transparency and accountability.",
      "alerts" => "Get notified before stock runs out and avoid delays."
    }[feature] || "Unlock this feature to improve your workflow."
  end

  def feature_benefits(feature)
    {
      "trends" => [
        "Visualize demand patterns",
        "Identify fast-moving products",
        "Optimize inventory decisions"
      ],
      "audits" => [
        "Full activity history",
        "Track user actions",
        "Improve accountability"
      ],
      "alerts" => [
        "Low stock notifications",
        "Prevent stockouts",
        "Stay proactive"
      ]
    }[feature] || ["Improve efficiency", "Save time", "Scale faster"]
  end

  def available_upgrade_plans(current_plan)
    case current_plan
    when "free"
      ["basic", "premium"]
    when "basic"
      ["premium"]
    else
      []
    end
  end

end