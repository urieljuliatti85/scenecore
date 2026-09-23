class Admin::BandVerificationRequestsController < Admin::BaseController
  before_action :set_band_verification_request, only: [ :approve, :reject, :resend ]

  def index
    @band_verification_requests = BandVerificationRequest.includes(:band).order(created_at: :desc)
  end

  # Approving does not verify the band yet — it only confirms, outside
  # SceneCore, that the submitted address is genuinely the band's own, and
  # sends the emailed link that the band itself must open.
  def approve
    authorize @band_verification_request

    @band_verification_request.email_sent!
    log_admin_action("approve_band_verification_request")
    deliver
    redirect_to admin_band_verification_requests_path, notice: "Approved. A verification email was sent to #{@band_verification_request.email}."
  end

  def reject
    authorize @band_verification_request

    @band_verification_request.rejected!
    log_admin_action("reject_band_verification_request")
    redirect_to admin_band_verification_requests_path, notice: "Request rejected."
  end

  # Mints a fresh token (generates_token_for is derived, not stored, so a
  # new email naturally carries a new link) and re-sends — for a band that
  # never received or lost the original email. Only reachable while still
  # email_sent, so an already-verified or rejected request can't be
  # re-triggered.
  def resend
    authorize @band_verification_request, :resend?

    unless @band_verification_request.email_sent?
      return redirect_to admin_band_verification_requests_path, alert: "Only a request awaiting the band's click can be re-sent."
    end

    log_admin_action("resend_band_verification_request")
    deliver
    redirect_to admin_band_verification_requests_path, notice: "Verification email re-sent to #{@band_verification_request.email}."
  end

  private

  def set_band_verification_request
    @band_verification_request = BandVerificationRequest.find(params[:id])
  end

  def log_admin_action(action)
    AdminActionLog.create!(actor: current_user, action: action, subject: @band_verification_request.band)
  end

  # The decision is already recorded either way, so a mail failure must
  # not roll back the approval and must not surface as an error to the
  # administrator who just made the call — same shape as
  # Admin::BandAdminRequestsController#deliver.
  def deliver
    BandVerificationMailer.verify(@band_verification_request).deliver_later
  rescue StandardError => e
    Rails.logger.error("BandVerificationRequest #{@band_verification_request.id} approved but not emailed: #{e.class}")
    Sentry.capture_exception(e) if defined?(Sentry)
  end
end
