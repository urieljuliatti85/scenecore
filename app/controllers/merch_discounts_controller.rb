class MerchDiscountsController < ApplicationController
  before_action :set_band

  def update
    authorize @band, :update?, policy_class: BandPolicy

    Membership::LEVELS.each do |level|
      percentage = discount_params[level]
      next if percentage.blank?

      @band.merch_discounts.find_or_initialize_by(level: level).update!(percentage: percentage)
    end

    redirect_to edit_band_path(@band), notice: "Merch discounts updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to edit_band_path(@band), alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def discount_params
    params.require(:merch_discounts).permit(Membership::LEVELS)
  end
end
