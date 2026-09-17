class ProductVariantsController < ApplicationController
  before_action :set_band
  before_action :set_product
  before_action :set_variant, only: [ :edit, :update, :destroy ]

  def new
    @variant = @product.variants.new
    authorize @variant
  end

  def create
    @variant = @product.variants.new(variant_params)
    authorize @variant

    if @variant.save
      redirect_to edit_band_product_path(@band, @product), notice: "Variant added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @variant
  end

  def update
    authorize @variant

    if @variant.update(variant_params)
      redirect_to edit_band_product_path(@band, @product), notice: "Variant updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @variant

    if @product.variants.count <= 1
      redirect_to edit_band_product_path(@band, @product), alert: "A product must keep at least one variant."
    else
      @variant.destroy!
      redirect_to edit_band_product_path(@band, @product), notice: "Variant deleted."
    end
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_product
    @product = @band.products.find(params[:product_id])
  end

  def set_variant
    @variant = @product.variants.find(params[:id])
  end

  def variant_params
    params.require(:product_variant).permit(:sku, :name, :price_cents, :stock_quantity)
  end
end
