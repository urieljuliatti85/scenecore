class ProductsController < ApplicationController
  before_action :set_band
  before_action :set_product, only: [ :edit, :update, :destroy, :publish, :unpublish ]

  def index
    authorize @band, policy_class: ProductPolicy
    @products = @band.products.includes(:variants).order(created_at: :desc)
  end

  def new
    @product = @band.products.new
    @product.variants.build(name: "Default", stock_quantity: 0)
    authorize @product
  end

  def create
    @product = @band.products.new(product_params)
    authorize @product

    if @product.variants.empty?
      @product.errors.add(:variants, "must include at least one variant")
      @product.variants.build(name: "Default", stock_quantity: 0)
      return render :new, status: :unprocessable_entity
    end

    if @product.save
      redirect_to band_products_path(@band), notice: "Product created."
    else
      @product.variants.build(name: "Default", stock_quantity: 0) if @product.variants.empty?
      render :new, status: :unprocessable_entity
    end
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
