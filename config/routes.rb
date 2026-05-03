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

  # ===============================
  # PLANS / PRICING
  # ===============================
  get "/plans/:plan", to: "plans#select", as: :select_plan

  # ===============================
  # BILLING (GLOBAL - NO ORG CONTEXT)
  # ===============================
  get "billing/checkout", to: "billing#checkout"
  get "billing/success", to: "billing#success"

  resource :billing, controller: "billing", only: [:show] do
    get :create_portal
    post :cancel_subscription
    patch :change_plan
  end

  # routes.rb
  get "/suspended", to: "home#suspended"

  get "upgrade", to: "billing#upgrade", as: :upgrade

  # ===============================
  # ADMIN (GLOBAL)
  # ===============================
  get "/admin", to: "admin/dashboard#index"

  namespace :admin do
    root "dashboard#index"

    resources :organizations do
      member do
        patch :suspend
        patch :activate
        delete :destroy
        post :impersonate
        post :reset_data
      end
    end
  end

  # ===============================
  # ORGANIZATION ONBOARDING
  # ===============================
  resources :organizations, only: [:new, :create]

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # ===============================
  # 🏢 TENANT (ORG-SCOPED)
  # ===============================
  scope "/app/organizations/:organization_id", as: "" do
      # Dashboard
      get "dashboard", to: "dashboard#index", as: :dashboard

      # Staff / Users
      resources :staffs, controller: "users", only: [:index, :new, :create, :destroy] do
        member do
          get :permissions
          patch :permissions, action: :update_permissions
        end
      end

      resource :notification_preference, only: [:update]
      # Products
      resources :products do
        member do
          patch :update_stock
        end
      end

      # Product Types
      resources :product_types

      # Requests
      get "requests", to: "owner#pending_requests", as: :pending_requests

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

      # Reports / Insights
      get "history", to: "owner#history"
      get "alerts", to: "owner#alerts"
      get "trends", to: "owner#trends"
      get "intelligence", to: "owner#intelligence"
      resources :audits, only: [:index, :show]

      # PDF Export
      get "owner/history.pdf",
          to: "owner#history",
          defaults: { format: :pdf },
          as: :owner_history_pdf

      post "history/send_email",
           to: "owner#send_history_pdf_email"

      # Recycle Bin
      get "recycle_bin", to: "recycle_bin#index", as: :recycle_bin

      patch "recycle_bin/products/:id/restore",
            to: "recycle_bin#restore_product",
            as: :restore_product

      patch "recycle_bin/users/:id/restore",
            to: "recycle_bin#restore_user",
            as: :restore_staff
  end

  # ===============================
  # WEBHOOKS (GLOBAL)
  # ===============================
  post "/stripe/webhook", to: "webhooks#stripe"
  post "/webhooks", to: "webhooks#stripe"
  post "/webhooks/sendgrid", to: "webhooks#sendgrid"

  # (Optional legacy)
  post "/subscriptions", to: "subscriptions#create"
  post "/billing", to: "billing#portal"
end