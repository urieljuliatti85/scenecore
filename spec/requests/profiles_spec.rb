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
