Rails.application.routes.draw do
  # Active Storage's default blob redirect route is publicly accessible to
  # anyone with the URL, forever, with no authorization check (Rails' own
  # controller source warns about this explicitly). This adds a
  # separately-named route pointed at AuthenticatedBlobsController, which
  # checks the attachment's owning record is actually visible to the
  # current viewer before redirecting to the file. Active Storage's own
  # routes (including the original, unauthenticated rails_service_blob)
  # are left intact below — `config.active_storage.resolve_model_to_route`
  # in config/application.rb is what makes `rails_blob_path`/`image_tag`
  # actually use this route instead of the original.
  get "/rails/active_storage/blobs/authenticated/:signed_id/*filename",
      to: "authenticated_blobs#show", as: :rails_authenticated_service_blob

  # Neutralizes Active Storage's own blob redirect routes (unauthenticated
  # by default) so they can't be used as a bypass now that rails_blob_path
  # generates authenticated URLs instead (see resolve_model_to_route
  # above). Declared without `:as` so they don't conflict with the
  # engine's own route names, and take precedence because app routes are
  # always matched before routes contributed by mounted engines.
  get "/rails/active_storage/blobs/redirect/:signed_id/*filename", to: "authenticated_blobs#show"
  get "/rails/active_storage/blobs/:signed_id/*filename", to: "authenticated_blobs#show"

  direct :rails_authenticated_storage_redirect do |model, options|
    expires_in = options.delete(:expires_in) { ActiveStorage.urls_expire_in }
    expires_at = options.delete(:expires_at)
    signed_id = model.respond_to?(:signed_id) ? model.signed_id(expires_in: expires_in, expires_at: expires_at) : model.blob.signed_id(expires_in: expires_in, expires_at: expires_at)
    filename = model.respond_to?(:filename) ? model.filename : model.blob.filename

    route_for(:rails_authenticated_service_blob, signed_id, filename, options)
  end

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
    resources :categories, only: [ :index, :new, :create, :edit, :update, :destroy ]
  end

  resources :bands, only: [ :index, :new, :create, :show, :edit, :update ] do
    member do
      patch :approve
      patch :reject
      patch :suspend
      patch :reactivate
    end

    resources :band_memberships, only: [ :index, :new, :create, :edit, :update, :destroy ], path: "members"
    resources :albums, only: [ :new, :create, :show, :edit, :update ] do
      member do
        patch :publish
        patch :unpublish
        patch :refetch_cover
        patch :cover_from_url
      end
      collection do
        get :search
      end
    end
    resources :tracks, only: [ :edit, :update ]
    resource :follow, only: [ :create, :destroy ]
    resources :posts, only: [ :new, :create, :show, :edit, :update, :destroy ] do
      member do
        patch :publish
        patch :unpublish
      end
    end
  end

  # Defines the root path route ("/")
  root "pages#home"

  # Public directory of approved bands. "/bands" is already taken by the
  # management area (BandsController#index, "Your bands"), so this lives
  # at "/discover" instead.
  get "/discover", to: "public_bands#index", as: :discover_bands

  get "/search", to: "search#index", as: :search

  # Public band page and album detail, resolved by slug. Must stay last
  # so they don't shadow any of the routes declared above.
  get "/:slug/albums/:id", to: "public_bands#album", as: :public_band_album, constraints: { slug: /[a-z0-9\-]+/ }
  get "/:slug", to: "public_bands#show", as: :public_band, constraints: { slug: /[a-z0-9\-]+/ }
end
