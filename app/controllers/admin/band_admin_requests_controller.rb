class Admin::BandAdminRequestsController < Admin::BaseController
  before_action :set_band_admin_request, only: [ :approve, :reject, :revoke ]

  def index
    @band_admin_requests = BandAdminRequest.includes(:user, :band).order(created_at: :desc)
  end

  def approve
    authorize @band_admin_request

    ActiveRecord::Base.transaction do
      membership = @band_admin_request.band.band_memberships.find_or_initialize_by(user_id: @band_admin_request.user_id)
      membership.role = :administrator
      membership.save!
      @band_admin_request.approved!
    end

    log_admin_action("approve_band_admin_request")
    deliver(:approved)
    redirect_to admin_band_admin_requests_path, notice: "Request approved. #{requester_name} is now an administrator of #{band_name}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_band_admin_requests_path, alert: e.record.errors.full_messages.to_sentence
  end

  def reject
    authorize @band_admin_request

    @band_admin_request.rejected!
    deliver(:rejected)

    redirect_to admin_band_admin_requests_path, notice: "Request rejected."
  end

  def revoke
    authorize @band_admin_request, :revoke?

    @band_admin_request.revoked!
    redirect_to admin_band_admin_requests_path, notice: "Request withdrawn."
  end

  private

  def set_band_admin_request
    @band_admin_request = BandAdminRequest.find(params[:id])
  end

  def requester_name
    @band_admin_request.user.name
  end

  def band_name
    @band_admin_request.band.name
  end

  def log_admin_action(action)
    AdminActionLog.create!(actor: current_user, action: action, subject: @band_admin_request.band)
  end

  # The decision is already recorded either way, so a mail failure must
  # not roll back the approval/rejection or surface as an error to the
  # administrator who just made the call — same shape as
  # ContactMessagesController#deliver.
  def deliver(outcome)
    BandAdminRequestMailer.public_send(outcome, @band_admin_request).deliver_later
  rescue StandardError => e
    Rails.logger.error("BandAdminRequest #{@band_admin_request.id} decided (#{outcome}) but not emailed: #{e.class}")
    Sentry.capture_exception(e) if defined?(Sentry)
  end
end
