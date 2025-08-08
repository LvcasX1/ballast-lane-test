Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :books
  resources :users, except: [ :create ]

  # Custom registration endpoint
  post "sign-up", to: "users#create"

  # Borrowings
  resources :borrowings, only: [ :create, :show ] do
    member do
      post :return, to: "borrowings#return_book"
    end
  end

  # Dashboards (root)
  get "dashboard/librarian", to: "dashboards#librarian"
  get "dashboard/member", to: "dashboards#member"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
