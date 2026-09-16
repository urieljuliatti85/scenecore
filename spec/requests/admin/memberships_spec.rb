require "rails_helper"

RSpec.describe "Admin::Memberships", type: :request do
  describe "GET /admin/memberships" do
    it "lists all memberships for a platform admin" do
      admin = create(:user, :platform_admin)
      fan_user = create(:user, name: "Fan User")
      supporter_user = create(:user, name: "Supporter User")
      create(:membership, user: fan_user, level: :fan)
      create(:membership, :supporter, user: supporter_user)
      sign_in admin

      get admin_memberships_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Fan User")
      expect(response.body).to include("Supporter User")
    end

    it "filters by level" do
      admin = create(:user, :platform_admin)
      create(:membership, user: create(:user, name: "Fan User"), level: :fan)
      create(:membership, :core_member, user: create(:user, name: "Core User"))
      sign_in admin

      get admin_memberships_path(level: "core_member")

      expect(response.body).to include("Core User")
      expect(response.body).not_to include("Fan User")
    end

    it "filters by status" do
      admin = create(:user, :platform_admin)
      create(:membership, user: create(:user, name: "Active User"))
      create(:membership, :paused, user: create(:user, name: "Paused User"))
      sign_in admin

      get admin_memberships_path(status: "paused")

      expect(response.body).to include("Paused User")
      expect(response.body).not_to include("Active User")
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      sign_in user

      get admin_memberships_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_memberships_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
