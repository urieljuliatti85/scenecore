class Admin::PrivilegesController < Admin::BaseController
  before_action :set_band
  before_action :set_membership, only: [ :update ]

  def index
    @memberships = @band.band_memberships.includes(:user).order(:role)
    @users_without_membership = User.where.not(id: @band.members.select(:id)).order(:name)
  end

  def create
    membership = @band.band_memberships.find_or_initialize_by(user_id: params[:user_id])
    membership.role = :administrator

    if membership.save
      redirect_to admin_band_privileges_path(@band), notice: "Administrator privileges granted."
    else
      redirect_to admin_band_privileges_path(@band), alert: membership.errors.full_messages.to_sentence
    end
  end

  def update
    if @membership.update(role: params[:role])
      redirect_to admin_band_privileges_path(@band), notice: "Role updated."
    else
      redirect_to admin_band_privileges_path(@band), alert: @membership.errors.full_messages.to_sentence
    end
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_membership
    @membership = @band.band_memberships.find(params[:id])
  end
end
