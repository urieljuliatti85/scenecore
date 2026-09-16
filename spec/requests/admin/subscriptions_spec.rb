require "rails_helper"

RSpec.describe "Admin::Subscriptions", type: :request do
  describe "GET /admin/subscriptions" do
    it "lists all subscriptions for a platform admin" do
      admin = create(:user, :platform_admin)
      create(:subscription, user: create(:user, name: "Pending User"))
      create(:subscription, :active, user: create(:user, name: "Active User"))
      sign_in admin

      get admin_subscriptions_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pending User")
      expect(response.body).to include("Active User")
    end

    it "shows the Stripe subscription id when present" do
      admin = create(:user, :platform_admin)
      create(:subscription, :active, stripe_subscription_id: "sub_visible123")
      sign_in admin

      get admin_subscriptions_path

      expect(response.body).to include("sub_visible123")
    end

    it "filters by level" do
      admin = create(:user, :platform_admin)
      create(:subscription, user: create(:user, name: "Fan User"), level: :fan)
      create(:subscription, :core_member, user: create(:user, name: "Core User"))
      sign_in admin

      get admin_subscriptions_path(level: "core_member")

      expect(response.body).to include("Core User")
      expect(response.body).not_to include("Fan User")
    end

    it "filters by status" do
      admin = create(:user, :platform_admin)
      create(:subscription, user: create(:user, name: "Pending User"))
      create(:subscription, :active, user: create(:user, name: "Active User"))
      sign_in admin

      get admin_subscriptions_path(status: "active")

      expect(response.body).to include("Active User")
      expect(response.body).not_to include("Pending User")
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      sign_in user

      get admin_subscriptions_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_subscriptions_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
