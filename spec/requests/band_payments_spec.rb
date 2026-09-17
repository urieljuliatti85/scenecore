require "rails_helper"

RSpec.describe "Band payments", type: :request do
  let(:band) { create(:band, :approved, name: "The Testers") }
  let(:admin) { create(:user) }

  def sign_in_as_administrator
    create(:band_membership, :administrator, band: band, user: admin)
    sign_in admin
  end

  describe "authorization" do
    it "requires signing in" do
      get band_payments_path(band)

      expect(response).to redirect_to(new_user_session_path)
    end

    # Payment settings are the band's own money, so a plain member sees
    # nothing of them.
    it "refuses a member who is not an administrator" do
      member = create(:user)
      create(:band_membership, band: band, user: member, role: :member)
      sign_in member

      get band_payments_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "refuses another band's administrator" do
      outsider = create(:user)
      create(:band_membership, :administrator, band: create(:band), user: outsider)
      sign_in outsider

      get band_payments_path(band)

      expect(response).to redirect_to(root_path)
    end

    it "lets this band's administrator in" do
      sign_in_as_administrator

      get band_payments_path(band)

      expect(response).to have_http_status(:ok)
    end
  end

  # Each Connect status leaves the band in a different position, so the page
  # names which one rather than printing the enum.
  describe "connect status" do
    before { sign_in_as_administrator }

    it "explains that Stripe is not connected yet" do
      get band_payments_path(band)

      expect(response.body).to include("haven&#39;t connected Stripe yet")
    end

    it "explains an unfinished onboarding" do
      band.update!(stripe_connect_status: :onboarding, stripe_connect_account_id: "acct_1")

      get band_payments_path(band)

      expect(response.body).to include("still needs some details")
    end

    it "explains a restricted account" do
      band.update!(stripe_connect_status: :restricted, stripe_connect_account_id: "acct_1")

      get band_payments_path(band)

      expect(response.body).to include("has restricted your account")
    end

    it "confirms an active account and links to the Stripe dashboard" do
      band.update!(stripe_connect_status: :active, stripe_connect_account_id: "acct_1")

      get band_payments_path(band)

      expect(response.body).to include("set up to receive payments")
      expect(response.body).to include("dashboard.stripe.com")
    end
  end

  describe "what is blocked" do
    before { sign_in_as_administrator }

    # Memberships began routing payment to the connected account too, so a
    # band without one loses both, not just the Store.
    it "names memberships and the Store while the account is not ready" do
      get band_payments_path(band)

      expect(response.body).to include("What this blocks")
      expect(response.body).to include("can't start a membership")
      expect(response.body).to include("can't buy from your Store")
    end

    it "says nothing is blocked once the account is active" do
      band.update!(stripe_connect_status: :active, stripe_connect_account_id: "acct_1")

      get band_payments_path(band)

      expect(response.body).not_to include("What this blocks")
    end

    # A band with people already waiting is in a different position from one
    # with nothing set up, so the page counts rather than generalising.
    it "counts the subscribers and products affected" do
      create(:subscription, :active, band: band, user: create(:user))
      create(:product, :published, band: band)

      get band_payments_path(band)

      expect(response.body).to include("1 existing subscriber")
      expect(response.body).to include("1 published product")
    end
  end

  describe "the split" do
    before { sign_in_as_administrator }

    it "quotes what the band keeps from each revenue stream" do
      get band_payments_path(band)

      expect(response.body).to include("85%")
      expect(response.body).to include("90%")
    end
  end

  describe "discoverability" do
    before { sign_in_as_administrator }

    # A band that sells no merch has no reason to open Products, which is
    # where the only Connect prompt used to live.
    it "is linked from the band panel" do
      get band_path(band)

      expect(response.body).to include(band_payments_path(band))
    end

    it "flags the panel link while payments are not set up" do
      get band_path(band)

      link = Nokogiri::HTML(response.body).css("a[href='#{band_payments_path(band)}']").first

      expect(link["class"]).to include("yellow")
    end

    it "stops flagging it once the account is active" do
      band.update!(stripe_connect_status: :active, stripe_connect_account_id: "acct_1")

      get band_path(band)

      link = Nokogiri::HTML(response.body).css("a[href='#{band_payments_path(band)}']").first

      expect(link["class"]).not_to include("yellow")
    end
  end
end
