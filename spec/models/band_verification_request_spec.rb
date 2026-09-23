require "rails_helper"

RSpec.describe BandVerificationRequest do
  describe "validations" do
    it "requires a plausible email" do
      request = build(:band_verification_request, email: "not-an-email")

      expect(request).not_to be_valid
      expect(request.errors[:email]).to be_present
    end

    it "is valid with a plausible email" do
      request = build(:band_verification_request, email: "official@band.example")

      expect(request).to be_valid
    end

    # At most one open (pending or email_sent) request per band, mirroring
    # BandAdminRequest's partial-unique-index shape — a band should not be
    # able to stack duplicate submissions while one is already in flight.
    it "refuses a second pending request for a band that already has one open" do
      band = create(:band)
      create(:band_verification_request, band: band)

      duplicate = build(:band_verification_request, band: band, email: "another@band.example")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:band_id]).to be_present
    end

    it "refuses a second request while one is email_sent" do
      band = create(:band)
      create(:band_verification_request, :email_sent, band: band)

      duplicate = build(:band_verification_request, band: band, email: "another@band.example")

      expect(duplicate).not_to be_valid
    end

    it "allows a new request once the previous one is verified" do
      band = create(:band)
      create(:band_verification_request, :verified, band: band)

      new_request = build(:band_verification_request, band: band, email: "another@band.example")

      expect(new_request).to be_valid
    end

    it "allows a new request once the previous one is rejected" do
      band = create(:band)
      create(:band_verification_request, :rejected, band: band)

      new_request = build(:band_verification_request, band: band, email: "another@band.example")

      expect(new_request).to be_valid
    end
  end

  describe "#verify!" do
    it "marks the request verified and the band verified" do
      band = create(:band, verified: false)
      request = create(:band_verification_request, :email_sent, band: band)

      request.verify!

      expect(request.reload).to be_verified
      expect(band.reload).to be_verified
    end
  end

  describe "token generation" do
    it "resolves a valid token back to the request" do
      request = create(:band_verification_request, :email_sent)
      token = request.generate_token_for(:band_verification)

      expect(described_class.find_by_token_for(:band_verification, token)).to eq(request)
    end

    it "does not resolve an expired token" do
      request = create(:band_verification_request, :email_sent)
      token = travel_to(4.days.ago) { request.generate_token_for(:band_verification) }

      expect(described_class.find_by_token_for(:band_verification, token)).to be_nil
    end

    it "still resolves a token just before its 3-day expiry" do
      request = create(:band_verification_request, :email_sent)
      token = travel_to(2.days.ago) { request.generate_token_for(:band_verification) }

      expect(described_class.find_by_token_for(:band_verification, token)).to eq(request)
    end

    it "does not resolve garbage" do
      expect(described_class.find_by_token_for(:band_verification, "not-a-real-token")).to be_nil
    end
  end
end
