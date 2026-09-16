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

  describe "PATCH /admin/memberships/:id/pause" do
    it "pauses an active membership for a platform admin" do
      admin = create(:user, :platform_admin)
      membership = create(:membership, status: :active)
      sign_in admin

      patch pause_admin_membership_path(membership)

      expect(response).to redirect_to(admin_memberships_path)
      expect(membership.reload).to be_paused
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      membership = create(:membership, status: :active)
      sign_in user

      patch pause_admin_membership_path(membership)

      expect(response).to have_http_status(:not_found)
      expect(membership.reload).to be_active
    end
  end

  describe "PATCH /admin/memberships/:id/cancel" do
    it "cancels a membership for a platform admin" do
      admin = create(:user, :platform_admin)
      membership = create(:membership, status: :active)
      sign_in admin

      patch cancel_admin_membership_path(membership)

      expect(response).to redirect_to(admin_memberships_path)
      expect(membership.reload).to be_cancelled
    end
  end

  describe "PATCH /admin/memberships/:id/reactivate" do
    it "reactivates a paused membership for a platform admin" do
      admin = create(:user, :platform_admin)
      membership = create(:membership, :paused)
      sign_in admin

      patch reactivate_admin_membership_path(membership)

      expect(response).to redirect_to(admin_memberships_path)
      expect(membership.reload).to be_active
    end
  end

  describe "GET /admin/memberships/:id/edit" do
    it "shows the edit form for a platform admin" do
      admin = create(:user, :platform_admin)
      membership = create(:membership, :fan, user: create(:user, name: "Fan User"))
      sign_in admin

      get edit_admin_membership_path(membership)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Fan User")
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      membership = create(:membership)
      sign_in user

      get edit_admin_membership_path(membership)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /admin/memberships/:id" do
    it "lets a platform admin change a membership's level" do
      admin = create(:user, :platform_admin)
      membership = create(:membership, :fan)
      sign_in admin

      patch admin_membership_path(membership), params: { membership: { level: "core_member" } }

      expect(response).to redirect_to(admin_memberships_path)
      expect(membership.reload.level).to eq("core_member")
    end

    it "does not let a platform admin change a membership's status through this action" do
      admin = create(:user, :platform_admin)
      membership = create(:membership, :fan, status: :active)
      sign_in admin

      patch admin_membership_path(membership), params: { membership: { level: "supporter", status: "cancelled" } }

      expect(membership.reload.status).to eq("active")
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      membership = create(:membership, :fan)
      sign_in user

      patch admin_membership_path(membership), params: { membership: { level: "core_member" } }

      expect(response).to have_http_status(:not_found)
      expect(membership.reload.level).to eq("fan")
    end
  end

  describe "DELETE /admin/memberships/:id" do
    it "lets a platform admin permanently remove a membership" do
      admin = create(:user, :platform_admin)
      membership = create(:membership)
      sign_in admin

      expect {
        delete admin_membership_path(membership)
      }.to change(Membership, :count).by(-1)
      expect(response).to redirect_to(admin_memberships_path)
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      membership = create(:membership)
      sign_in user

      expect {
        delete admin_membership_path(membership)
      }.not_to change(Membership, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
