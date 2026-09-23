require "rails_helper"

RSpec.describe "Admin::BandVerificationRequests", type: :request do
  describe "GET /admin/band_verification_requests" do
    it "lists requests for a platform admin" do
      admin = create(:user, :platform_admin)
      band = create(:band, name: "Requesting Band")
      create(:band_verification_request, band: band)
      sign_in admin

      get admin_band_verification_requests_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Requesting Band")
    end

    it "returns 404 for a regular authenticated user" do
      sign_in create(:user)

      get admin_band_verification_requests_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_band_verification_requests_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "PATCH /admin/band_verification_requests/:id/approve" do
    it "moves the request to email_sent without verifying the band yet" do
      admin = create(:user, :platform_admin)
      request = create(:band_verification_request)
      sign_in admin

      patch approve_admin_band_verification_request_path(request)

      expect(request.reload).to be_email_sent
      expect(request.band.reload).not_to be_verified
    end

    it "sends the verification email" do
      admin = create(:user, :platform_admin)
      request = create(:band_verification_request)
      sign_in admin

      expect {
        patch approve_admin_band_verification_request_path(request)
      }.to have_enqueued_mail(BandVerificationMailer, :verify)
    end

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      request = create(:band_verification_request)
      sign_in admin

      expect {
        patch approve_admin_band_verification_request_path(request)
      }.to change(AdminActionLog, :count).by(1)

      expect(AdminActionLog.last.action).to eq("approve_band_verification_request")
    end

    it "does not allow a regular user to approve" do
      user = create(:user)
      request = create(:band_verification_request)
      sign_in user

      patch approve_admin_band_verification_request_path(request)

      expect(request.reload).to be_pending
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /admin/band_verification_requests/:id/reject" do
    it "marks the request rejected" do
      admin = create(:user, :platform_admin)
      request = create(:band_verification_request)
      sign_in admin

      patch reject_admin_band_verification_request_path(request)

      expect(request.reload).to be_rejected
    end

    it "does not send an email" do
      admin = create(:user, :platform_admin)
      request = create(:band_verification_request)
      sign_in admin

      expect {
        patch reject_admin_band_verification_request_path(request)
      }.not_to have_enqueued_mail(BandVerificationMailer, :verify)
    end

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      request = create(:band_verification_request)
      sign_in admin

      expect {
        patch reject_admin_band_verification_request_path(request)
      }.to change(AdminActionLog, :count).by(1)

      expect(AdminActionLog.last.action).to eq("reject_band_verification_request")
    end

    it "does not block the band from requesting again afterwards" do
      admin = create(:user, :platform_admin)
      request = create(:band_verification_request)
      sign_in admin
      patch reject_admin_band_verification_request_path(request)

      new_request = build(:band_verification_request, band: request.band)

      expect(new_request).to be_valid
    end
  end

  describe "PATCH /admin/band_verification_requests/:id/resend" do
    it "re-sends the email for a request awaiting the band's click" do
      admin = create(:user, :platform_admin)
      request = create(:band_verification_request, :email_sent)
      sign_in admin

      expect {
        patch resend_admin_band_verification_request_path(request)
      }.to have_enqueued_mail(BandVerificationMailer, :verify)
    end

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      request = create(:band_verification_request, :email_sent)
      sign_in admin

      expect {
        patch resend_admin_band_verification_request_path(request)
      }.to change(AdminActionLog, :count).by(1)
    end

    it "refuses to resend a still-pending (not yet approved) request" do
      admin = create(:user, :platform_admin)
      request = create(:band_verification_request)
      sign_in admin

      expect {
        patch resend_admin_band_verification_request_path(request)
      }.not_to have_enqueued_mail(BandVerificationMailer, :verify)

      expect(flash[:alert]).to be_present
    end

    it "refuses to resend an already-verified request" do
      admin = create(:user, :platform_admin)
      request = create(:band_verification_request, :verified)
      sign_in admin

      expect {
        patch resend_admin_band_verification_request_path(request)
      }.not_to have_enqueued_mail(BandVerificationMailer, :verify)
    end

    it "does not allow a regular user to resend" do
      user = create(:user)
      request = create(:band_verification_request, :email_sent)
      sign_in user

      patch resend_admin_band_verification_request_path(request)

      expect(response).to have_http_status(:not_found)
    end
  end
end
