class DirectMessageThreadsController < ApplicationController
  before_action :set_band
  before_action :set_thread, only: [ :show, :archive, :block, :unblock ]

  def index
    authorize @band, :show?, policy_class: BandPolicy

    @threads = @band.direct_message_threads.includes(:user).order(updated_at: :desc)
  end

  def show
    authorize @thread
  end

  def archive
    authorize @thread, :archive?
    @thread.archived!

    redirect_to band_direct_message_thread_path(@band, @thread), notice: "Thread archived."
  end

  def block
    authorize @thread, :block?
    @thread.blocked!
    log_platform_moderation("moderate_block_direct_message_thread")

    redirect_to band_direct_message_thread_path(@band, @thread), notice: "This member can no longer send messages."
  end

  def unblock
    authorize @thread, :unblock?
    @thread.open!

    redirect_to band_direct_message_thread_path(@band, @thread), notice: "This member can send messages again."
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_thread
    @thread = @band.direct_message_threads.find(params[:id])
  end

  # Platform moderation must be auditable (docs/community.md §11) — a band
  # blocking a thread on its own band is ordinary moderation of its own
  # community, not a platform intervention.
  def log_platform_moderation(action)
    return unless current_user.platform_admin?
    return if @band.band_memberships.exists?(user_id: current_user.id)

    AdminActionLog.create!(actor: current_user, action: action, subject: @thread)
  end
end
