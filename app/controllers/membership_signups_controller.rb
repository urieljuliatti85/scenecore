class MembershipSignupsController < ApplicationController
  before_action :set_band

  def create
    @membership = @band.memberships.find_or_initialize_by(user: current_user)
    authorize @membership, :join?

    @membership.level = membership_params[:level]
    @membership.status = :active

    if @membership.save
      redirect_to public_band_path(@band.slug), notice: "You're now a #{@membership.level.humanize} member of #{@band.name}."
    else
      redirect_to public_band_path(@band.slug), alert: @membership.errors.full_messages.to_sentence
    end
  end

  private

  def set_band
    @band = Band.approved.find(params[:band_id])
  end

  def membership_params
    params.require(:membership).permit(:level)
  end
end
