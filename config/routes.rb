Rails.application.routes.draw do

  # ===============================
  # DEV / HEALTH
  # ===============================
  get "up" => "rails/health#show", as: :rails_health_check

  # ===============================
  # AUTH (GLOBAL)
  # ===============================
  devise_for :users, controllers: {
    sessions: "users/sessions"
  }

  root "home#index"

  get "/plans/:plan", to: "plans#select", as: :select_plan

  # ===============================
  # BILLING
  # ===============================
  get "billing/checkout", to: "billing#checkout"
  get "billing/success", to: "billing#success"

  # ===============================
  # ORGANIZATION ONBOARDING
  # ===============================
  resources :organizations, only: [:new, :create]
  # ===============================
  # 🏢 TENANT DOMAIN (ONLY REAL ORGANIZATIONS)

  # ===============================

  scope "/app" do
    get "dashboard", to: "dashboard#index", as: :dashboard

    resources :staffs, controller: "users", only: [:index, :new, :create, :destroy] do
      member do
        get :permissions
        patch :permissions, action: :update_permissions
      end
    end
    resources :products do
      member do
        patch :update_stock
      end
    end
    resources :product_types
    get 'requests', to: 'owner#pending_requests', as: :pending_requests
    post "requests/approve_all",
        to: "owner#approve_all_requests",
        as: :approve_all_requests
    resources :requests do
      member do
        patch :approve
        patch :reject
        patch :cancel
      end
    end

    get "history", to: "owner#history"
    get "alerts", to: "owner#alerts"
    get "trends", to: "owner#trends"
    get "audits", to: "audits#index"

    get "owner/history.pdf",
        to: "owner#history",
        defaults: { format: :pdf },
        as: :owner_history_pdf

    post "history/send_email",
        to: "owner#send_history_pdf_email"

    get "recycle_bin", to: "recycle_bin#index", as: :recycle_bin

    patch "recycle_bin/products/:id/restore",
          to: "recycle_bin#restore_product",
          as: :restore_product

    patch "recycle_bin/users/:id/restore",
          to: "recycle_bin#restore_user",
          as: :restore_staff
  end

  # ===============================
  # WEBHOOKS
  # ===============================
  get "upgrade", to: "billing#upgrade", as: :upgrade
  post "/webhooks", to: "webhooks#receive"
end