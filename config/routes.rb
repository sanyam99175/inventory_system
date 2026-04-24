Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions'
  }

  # Handle OPTIONS requests (CORS preflight)
  match '*path', to: proc { |_env| [200, {}, ['']] }, via: [:options]

  # ===============================
  # 🌐 ROOT DOMAIN (no subdomain)
  # ===============================
  constraints subdomain: '' do
    root "home#index"

    resources :organizations, only: [:new, :create]
  end

  # ===============================
  # 🏢 TENANT (SUBDOMAIN)
  # ===============================
  constraints subdomain: /.+/ do
    root "home#index", as: :tenant_root

    resources :staffs, controller: "users", only: [:index, :new, :create, :destroy] do
      member do
        get :permissions
        patch :permissions, action: :update_permissions
      end
    end

    get "owner/dashboard", to: "owner#dashboard", as: :owner_dashboard
    get "worker/dashboard", to: "worker#dashboard", as: :worker_dashboard

    resources :products do
      member do
        patch :update_stock
      end
    end

    get "owner/history", to: "owner#history", as: :owner_history
    get "owner/alerts", to: "owner#alerts", as: :owner_alerts
    get "owner/pending_requests", to: "owner#pending_requests", as: :owner_pending_requests
    get "owner/trends", to: "owner#trends", as: :owner_trends

    get "owner/history.pdf",
        to: "owner#history",
        defaults: { format: :pdf },
        as: :owner_history_pdf

    post "owner/history/send_email",
        to: "owner#send_history_pdf_email",
        as: :owner_history_send_email

    post "owner/requests/approve_all",
        to: "owner#approve_all_requests",
        as: :approve_all_requests

    resources :requests do
      member do
        patch :approve
        patch :reject
        patch :cancel
      end
    end

    get "recycle_bin", to: "recycle_bin#index", as: :recycle_bin

    patch "recycle_bin/products/:id/restore",
          to: "recycle_bin#restore_product",
          as: :restore_product

    patch "recycle_bin/users/:id/restore",
          to: "recycle_bin#restore_user",
          as: :restore_staff

    get "audits", to: "audits#index", as: :audits
  end

  get "billing/checkout", to: "billing#checkout", as: :billing_checkout
  get "billing/success", to: "billing#success", as: :success_billing
  post "/webhooks", to: "webhooks#receive"
  get "/upgrade", to: "billing#upgrade", as: :upgrade
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end