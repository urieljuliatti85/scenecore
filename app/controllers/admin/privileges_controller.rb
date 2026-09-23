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
    self_granted = membership.user_id == current_user.id

    if membership.save
      # A platform admin granting themselves a membership is how they get
      # from moderation into day-to-day band work (BandPolicy#update? and
      # friends no longer bypass for a non-member). That door must leave a
      # trail the same way blocking a thread or unpublishing an album does.
      log_admin_action("grant_self_band_administrator") if self_granted
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

  def log_admin_action(action)
    AdminActionLog.create!(actor: current_user, action: action, subject: @band)
  end
end
