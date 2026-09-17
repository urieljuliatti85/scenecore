require "rails_helper"

RSpec.describe "Profiles", type: :request do
  describe "GET /profile" do
    it "redirects to sign in when unauthenticated" do
      get profile_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the current user's profile when authenticated" do
      user = create(:user, name: "Alice")
      sign_in user

      get profile_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Alice")
    end

    it "opens on the details tab" do
      sign_in create(:user, name: "Alice")

      get profile_path

      active = Nokogiri::HTML(response.body).css("a[aria-current='page']")

      expect(active.text).to include("Details")
    end

    it "shows the user's subscriptions on the subscriptions tab" do
      user = create(:user)
      band = create(:band, :approved, name: "The Testers")
      create(:subscription, user: user, band: band, level: :fan, status: :active)
      sign_in user

      get profile_path(tab: "subscriptions")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("The Testers")
      expect(Nokogiri::HTML(response.body).css("a[aria-current='page']").text).to include("Your Subscriptions")
    end

    it "lets a fan cancel from the subscriptions tab" do
      user = create(:user)
      band = create(:band, :approved)
      create(:subscription, user: user, band: band, level: :fan, status: :active)
      sign_in user

      get profile_path(tab: "subscriptions")

      expect(response.body).to include(band_subscription_path(band))
    end

    it "does not leak another user's subscriptions" do
      user = create(:user)
      other = create(:user)
      band = create(:band, :approved, name: "Not Yours")
      create(:subscription, user: other, band: band, level: :fan, status: :active)
      sign_in user

      get profile_path(tab: "subscriptions")

      expect(response.body).not_to include("Not Yours")
    end

    # The tab comes straight from the query string, so an unknown value has
    # to fall back rather than reach a render call with it.
    it "falls back to details for an unknown tab" do
      sign_in create(:user, name: "Alice")

      get profile_path(tab: "nope")

      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).css("a[aria-current='page']").text).to include("Details")
    end
  end

  describe "PATCH /profile" do
    it "updates the current user's profile" do
      user = create(:user)
      sign_in user

      patch profile_path, params: { user: { name: "New Name" } }

      expect(response).to redirect_to(profile_path)
      expect(user.reload.name).to eq("New Name")
    end

    it "re-renders with errors on invalid update" do
      user = create(:user)
      sign_in user

      patch profile_path, params: { user: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(user.reload.name).not_to eq("")
    end
  end
end
