Rails.application.routes.draw do
  get 'products/index'
  get 'products/show'
  get 'products/new'
  get 'products/edit'
  devise_for :users

  resources :users, only: [:index, :destroy]

  get 'home/index'

  root "home#index"

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
  get "owner/history.pdf", to: "owner#history", defaults: { format: :pdf }, as: :owner_history_pdf
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
  get "up" => "rails/health#show", as: :rails_health_check
end