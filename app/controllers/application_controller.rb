class ApplicationController < ActionController::Base
    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :set_global_counts

    protected

    def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :role])
        devise_parameter_sanitizer.permit(:account_update, keys: [:name])
    end

    def after_sign_in_path_for(resource)
        if resource.owner?
            owner_dashboard_path
        else
            worker_dashboard_path
        end
    end

    def after_sign_out_path_for(resource_or_scope)
        new_user_session_path
    end

    def set_global_counts
        return unless user_signed_in? && current_user.owner?

        @low_stock_count = Product.where("stock_count <= alert_limit").count
        @pending_requests_count = Request.pending.count
    end
end
