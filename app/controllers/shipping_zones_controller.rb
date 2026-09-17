class ShippingZonesController < ApplicationController
  before_action :set_band
  before_action :set_zone, only: [ :edit, :update, :destroy ]

  def index
    authorize @band, policy_class: ShippingZonePolicy
    @zones = @band.shipping_zones.includes(:zone_countries).ordered
  end

  def new
    @zone = @band.shipping_zones.new
    authorize @zone
  end

  def create
    @zone = @band.shipping_zones.new(zone_params)
    authorize @zone

    if save_with_countries
      redirect_to band_shipping_zones_path(@band), notice: "Shipping destination added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @zone
  end

  def update
    authorize @zone

    if save_with_countries
      redirect_to band_shipping_zones_path(@band), notice: "Shipping destination updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @zone
    @zone.destroy!
    redirect_to band_shipping_zones_path(@band), notice: "Shipping destination removed."
  end

  private

  # Countries arrive as a plain list of codes rather than nested
  # attributes, because the form is a set of checkboxes and the band thinks
  # in terms of "these are the countries in this destination", not of
  # individual join records. Rewriting the set in a transaction keeps a
  # failed save from leaving a zone half-assigned.
  def save_with_countries
    codes = submitted_country_codes
    @zone.assign_attributes(zone_params)

    return false unless countries_available?(codes)
    return false unless @zone.valid?

    ActiveRecord::Base.transaction do
      @zone.save!
      @zone.zone_countries.where.not(country_code: codes).destroy_all
      existing = @zone.zone_countries.reload.map(&:country_code)
      (codes - existing).each { |code| @zone.zone_countries.create!(band: @band, country_code: code) }
    end

    true
  end

  # A country belongs to at most one of a band's destinations, enforced by a
  # unique index. Checked before saving so a clash is reported as a form
  # error naming the country and the destination that already has it,
  # rather than surfacing as a rolled-back save.
  def countries_available?(codes)
    if codes.empty?
      @zone.errors.add(:base, "Pick at least one country for this destination.")
      return false
    end

    taken = @band.shipping_zone_countries.where(country_code: codes).includes(:shipping_zone)
    taken = taken.where.not(shipping_zone_id: @zone.id) if @zone.persisted?

    taken.each do |claim|
      @zone.errors.add(:base, "#{claim.country_name} is already in #{claim.shipping_zone.name}.")
    end

    taken.empty?
  end

  def submitted_country_codes
    Array(params[:shipping_zone]&.[](:country_codes))
      .map { |code| Country.normalize(code) }
      .select { |code| Country.valid?(code) }
      .uniq
  end

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_zone
    @zone = @band.shipping_zones.find(params[:id])
  end

  def zone_params
    params.require(:shipping_zone).permit(:name, :shipping_cents, :position)
  end
end
