module ApplicationHelper
    def with_org(path)
        "#{path}?org_id=#{current_organization.id}"
    end
end
