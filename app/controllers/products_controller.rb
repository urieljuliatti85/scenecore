class ProductsController < ApplicationController
  before_action :set_band
  before_action :set_product, only: [ :edit, :update, :destroy, :publish, :unpublish ]

  def index
    authorize @band, policy_class: ProductPolicy

    if request.format.json?
      results = DiscogsClient.new.search_releases(params[:q])
      return render json: results.map(&:to_h)
    end

    @products = @band.products.includes(:variants).order(created_at: :desc)
  rescue DiscogsClient::ConfigurationError
    render json: { error: "Discogs integration is not configured." }, status: :service_unavailable
  rescue DiscogsClient::ApiError => e
    Rails.logger.warn("Discogs search failed with HTTP #{e.status}")
    render json: { error: discogs_api_error_message(e.status) }, status: discogs_http_status(e.status)
  rescue DiscogsClient::Error
    render json: { error: "Discogs search is unavailable right now." }, status: :bad_gateway
  end

  def new
    @product = @band.products.new
    @product.variants.build(name: "Default", stock_quantity: 0)
    authorize @product
  end

  def create
    @product = @band.products.new(product_params)
    authorize @product

    import_from_discogs if params[:discogs_release_id].present?

    if @product.variants.empty?
      @product.errors.add(:variants, "must include at least one variant")
      @product.variants.build(name: "Default", stock_quantity: 0)
      return render :new, status: :unprocessable_entity
    end

    if @product.save
      notice = @product.discogs? ? "Product imported from Discogs." : "Product created."
      redirect_to band_products_path(@band), notice: notice
    else
      @product.variants.build(name: "Default", stock_quantity: 0) if @product.variants.empty?
      render :new, status: :unprocessable_entity
    end
  rescue DiscogsClient::ConfigurationError
    @product.errors.add(:base, "Discogs integration is not configured.")
    render :new, status: :service_unavailable
  rescue DiscogsClient::ApiError => e
    Rails.logger.warn("Discogs release import failed with HTTP #{e.status}")
    @product.errors.add(:base, discogs_api_error_message(e.status))
    render :new, status: discogs_http_status(e.status)
  rescue DiscogsClient::Error
    @product.errors.add(:base, "Could not import this release from Discogs. Please try again.")
    render :new, status: :bad_gateway
  end

  def edit
    authorize @product
  end

  def update
    authorize @product

    if @product.update(product_params)
      redirect_to band_products_path(@band), notice: "Product updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @product
    @product.destroy!
    redirect_to band_products_path(@band), notice: "Product deleted."
  end

  def publish
    authorize @product

    if @product.variants.exists?
      @product.published!
      redirect_to band_products_path(@band), notice: "Product published."
    else
      redirect_to band_products_path(@band), alert: "Add at least one variant before publishing."
    end
  end

  def unpublish
    authorize @product
    @product.draft!
    redirect_to band_products_path(@band), notice: "Product unpublished."
  end

  private

  def import_from_discogs
    details = DiscogsClient.new.fetch_release(params[:discogs_release_id])

    @product.assign_attributes(
      source: :discogs,
      discogs_release_id: details.discogs_release_id,
      name: details.title,
      artist_name: details.artist,
      release_year: details.year,
      release_format: details.format,
      label_name: details.label,
      catalog_number: details.catalog_number,
      barcode: details.barcode,
      discogs_metadata: details.metadata,
      discogs_synced_at: Time.current
    )
  end

  def discogs_api_error_message(status)
    case status.to_i
    when 401, 403
      "Discogs credentials were rejected. Check the Discogs credentials configured for SceneCore."
    when 429
      "Discogs rate limit reached. Please try again shortly."
    else
      "Discogs search is unavailable right now."
    end
  end

  def discogs_http_status(status)
    status.to_i == 429 ? :too_many_requests : :bad_gateway
  end

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_product
    @product = @band.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :name,
      :description,
      variants_attributes: [ :id, :sku, :name, :price_cents, :stock_quantity ]
    )
  end
end
