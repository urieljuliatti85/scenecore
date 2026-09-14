class BandMembershipsController < ApplicationController
  before_action :set_band
  before_action :set_membership, only: [ :edit, :update, :destroy ]

  def index
    authorize BandMembership.new(band: @band), :index?
    @memberships = @band.band_memberships.includes(:user)
  end

  def new
    @membership = @band.band_memberships.new
    authorize @membership
  end

  def create
    @membership = @band.band_memberships.new(membership_params)
    authorize @membership

    if @membership.save
      redirect_to band_band_memberships_path(@band), notice: "Member added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @membership
  end

  def update
    authorize @membership

    if @membership.update(role_params)
      redirect_to band_band_memberships_path(@band), notice: "Role updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @membership

    if @membership.destroy
      redirect_to band_band_memberships_path(@band), notice: "Member removed."
    else
      redirect_to band_band_memberships_path(@band), alert: @membership.errors.full_messages.to_sentence
    end
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_membership
    @membership = @band.band_memberships.find(params[:id])
  end

  def membership_params
    params.require(:band_membership).permit(:user_id, :role)
  end

  def role_params
    params.require(:band_membership).permit(:role)
  end
end
