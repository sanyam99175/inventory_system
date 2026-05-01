module ApplicationHelper
    def with_org(path)
        "#{path}?org_id=#{current_organization.id}"
    end

    def pagination_links(current_page, total_pages, param_name)
    return if total_pages <= 1

    window = 2
    start_page = [current_page - window, 1].max
    end_page   = [current_page + window, total_pages].min

    content_tag :div, class: "flex gap-2 items-center justify-center mt-4" do
        links = []

        # Prev
        if current_page > 1
        links << link_to("←", params.permit!.merge(param_name => current_page - 1),
            class: "px-2 py-1 border rounded")
        end

        (start_page..end_page).each do |page|
        links << link_to(page,
            params.permit!.merge(param_name => page),
            class: "px-3 py-1 rounded border #{page == current_page ? 'bg-blue-600 text-white' : ''}")
        end

        # Next
        if current_page < total_pages
        links << link_to("→", params.permit!.merge(param_name => current_page + 1),
            class: "px-2 py-1 border rounded")
        end

        links.join.html_safe
    end
    end
end
