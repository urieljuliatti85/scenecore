class MembershipsController < ApplicationController
  before_action :set_band
  before_action :set_membership, only: [ :edit, :update, :destroy ]

  def index
    authorize Membership.new(band: @band), :manage_supporters?
    @memberships = @band.memberships.includes(:user).order(created_at: :desc)
  end

  def new
    @membership = @band.memberships.new
    authorize @membership, :manage_supporters?
  end

  def create
    @membership = @band.memberships.new(membership_params)
    authorize @membership, :manage_supporters?

    if @membership.save
      redirect_to band_memberships_path(@band), notice: "Supporter added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @membership, :manage_supporters?
  end

  def update
    authorize @membership, :manage_supporters?

    if @membership.update(level_and_status_params)
      redirect_to band_memberships_path(@band), notice: "Membership updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @membership, :manage_supporters?

    @membership.destroy
    redirect_to band_memberships_path(@band), notice: "Supporter removed."
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_membership
    @membership = @band.memberships.find(params[:id])
  end

  def membership_params
    params.require(:membership).permit(:user_id, :level)
  end

  def level_and_status_params
    params.require(:membership).permit(:level, :status)
  end
end
