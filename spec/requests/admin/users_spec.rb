require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  describe "GET /admin/users" do
    it "lists all users for a platform admin" do
      admin = create(:user, :platform_admin)
      other = create(:user, name: "Jane Fan", email: "jane@example.com")
      sign_in admin

      get admin_users_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jane Fan")
      expect(response.body).to include("jane@example.com")
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      sign_in user

      get admin_users_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_users_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
