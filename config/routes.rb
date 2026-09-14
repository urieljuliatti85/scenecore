Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resource :profile, only: [ :show, :edit, :update ], controller: "profiles"

  namespace :admin do
    resources :bands, only: [ :index ] do
      resources :privileges, only: [ :index, :create, :update ]
    end
    resources :users, only: [ :index ]
    resources :albums, only: [ :index ] do
      member do
        patch :unpublish
      end
    end
  end

  resources :bands, only: [ :index, :new, :create, :show, :edit, :update ] do
    member do
      patch :approve
      patch :reject
      patch :suspend
      patch :reactivate
    end

    resources :band_memberships, only: [ :index, :new, :create, :edit, :update, :destroy ], path: "members"
    resources :albums, only: [ :new, :create ] do
      member do
        patch :publish
        patch :unpublish
      end
      collection do
        get :search
      end
    end
    resources :tracks, only: [ :edit, :update ]
    resource :follow, only: [ :create, :destroy ]
    resources :posts, only: [ :new, :create, :edit, :update, :destroy ] do
      member do
        patch :publish
        patch :unpublish
      end
    end
  end

  # Defines the root path route ("/")
  root "pages#home"

  # Public band page, resolved by slug. Must stay last so it doesn't
  # shadow any of the routes declared above.
  get "/:slug", to: "public_bands#show", as: :public_band, constraints: { slug: /[a-z0-9\-]+/ }
end
