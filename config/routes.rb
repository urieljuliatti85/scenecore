Rails.application.routes.draw do
  # Active Storage's own route-drawing is disabled (see
  # config/initializers/active_storage.rb) so the blob redirect route below
  # can point at AuthenticatedBlobsController instead of the engine's
  # default (publicly-accessible-to-anyone-with-the-URL) controller. The
  # rest of this scope mirrors the engine's routes.rb so direct uploads,
  # the disk service, and image variants keep working unchanged.
  scope ActiveStorage.routes_prefix do
    get "/blobs/redirect/:signed_id/*filename" => "authenticated_blobs#show", as: :rails_service_blob
    get "/blobs/proxy/:signed_id/*filename" => "active_storage/blobs/proxy#show", as: :rails_service_blob_proxy
    get "/blobs/:signed_id/*filename" => "authenticated_blobs#show"

    get "/representations/redirect/:signed_blob_id/:variation_key/*filename" => "active_storage/representations/redirect#show", as: :rails_blob_representation
    get "/representations/proxy/:signed_blob_id/:variation_key/*filename" => "active_storage/representations/proxy#show", as: :rails_blob_representation_proxy
    get "/representations/:signed_blob_id/:variation_key/*filename" => "active_storage/representations/redirect#show"

    get  "/disk/:encoded_key/*filename" => "active_storage/disk#show", as: :rails_disk_service
    put  "/disk/:encoded_token" => "active_storage/disk#update", as: :update_rails_disk_service
    post "/direct_uploads" => "active_storage/direct_uploads#create", as: :rails_direct_uploads
  end

  direct :rails_representation do |representation, options|
    route_for(ActiveStorage.resolve_model_to_route, representation, options)
  end

  resolve("ActiveStorage::Variant") { |variant, options| route_for(ActiveStorage.resolve_model_to_route, variant, options) }
  resolve("ActiveStorage::VariantWithRecord") { |variant, options| route_for(ActiveStorage.resolve_model_to_route, variant, options) }
  resolve("ActiveStorage::Preview") { |preview, options| route_for(ActiveStorage.resolve_model_to_route, preview, options) }

  direct :rails_blob do |blob, options|
    route_for(ActiveStorage.resolve_model_to_route, blob, options)
  end

  resolve("ActiveStorage::Blob")       { |blob, options| route_for(ActiveStorage.resolve_model_to_route, blob, options) }
  resolve("ActiveStorage::Attachment") { |attachment, options| route_for(ActiveStorage.resolve_model_to_route, attachment.blob, options) }

  direct :rails_storage_redirect do |model, options|
    expires_in = options.delete(:expires_in) { ActiveStorage.urls_expire_in }
    expires_at = options.delete(:expires_at)

    if model.respond_to?(:signed_id)
      route_for(
        :rails_service_blob,
        model.signed_id(expires_in: expires_in, expires_at: expires_at),
        model.filename,
        options
      )
    else
      signed_blob_id = model.blob.signed_id(expires_in: expires_in, expires_at: expires_at)
      variation_key  = model.variation.key
      filename       = model.blob.filename

      route_for(
        :rails_blob_representation,
        signed_blob_id,
        variation_key,
        filename,
        options
      )
    end
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
    resources :albums, only: [ :new, :create, :edit, :update ] do
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
