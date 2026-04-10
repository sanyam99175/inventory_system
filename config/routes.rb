Rails.application.routes.draw do
  get 'products/index'
  get 'products/show'
  get 'products/new'
  get 'products/edit'
  devise_for :users

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
  resources :requests do
    member do
      patch :approve
      patch :reject
    end
  end
  get "up" => "rails/health#show", as: :rails_health_check
end