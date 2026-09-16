require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  describe "GET /admin" do
    it "shows counts for a platform admin" do
      admin = create(:user, :platform_admin)
      create(:band, :approved)
      create(:band)
      create(:band)
      sign_in admin

      get admin_root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(">2<")
      expect(response.body).to include(">3<")
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      sign_in user

      get admin_root_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_root_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
