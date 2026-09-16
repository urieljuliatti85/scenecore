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

  describe "GET /admin/users/:id/edit" do
    it "shows the edit form for a platform admin" do
      admin = create(:user, :platform_admin)
      other = create(:user, name: "Jane Fan")
      sign_in admin

      get edit_admin_user_path(other)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jane Fan")
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      other = create(:user)
      sign_in user

      get edit_admin_user_path(other)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /admin/users/:id" do
    it "lets a platform admin update another user's name and email" do
      admin = create(:user, :platform_admin)
      other = create(:user, name: "Old Name", email: "old@example.com")
      sign_in admin

      patch admin_user_path(other), params: { user: { name: "New Name", email: "new@example.com" } }

      expect(response).to redirect_to(admin_users_path)
      other.reload
      expect(other.name).to eq("New Name")
      expect(other.email).to eq("new@example.com")
    end

    it "lets a platform admin promote another user to platform admin" do
      admin = create(:user, :platform_admin)
      other = create(:user)
      sign_in admin

      patch admin_user_path(other), params: { user: { platform_admin: true } }

      expect(other.reload.platform_admin?).to be true
    end

    it "lets a platform admin set a new password for another user" do
      admin = create(:user, :platform_admin)
      other = create(:user)
      sign_in admin

      patch admin_user_path(other), params: { user: { password: "newpassword123", password_confirmation: "newpassword123" } }

      other.reload
      expect(other.valid_password?("newpassword123")).to be true
    end

    it "does not change the password when the field is left blank" do
      admin = create(:user, :platform_admin)
      other = create(:user, password: "originalpassword123")
      sign_in admin

      patch admin_user_path(other), params: { user: { name: "New Name", password: "" } }

      expect(other.reload.valid_password?("originalpassword123")).to be true
    end

    it "prevents demoting the last platform admin" do
      admin = create(:user, :platform_admin)
      sign_in admin

      patch admin_user_path(admin), params: { user: { platform_admin: false } }

      expect(admin.reload.platform_admin?).to be true
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      other = create(:user, name: "Untouched")
      sign_in user

      patch admin_user_path(other), params: { user: { name: "Hacked" } }

      expect(response).to have_http_status(:not_found)
      expect(other.reload.name).to eq("Untouched")
    end
  end

  describe "DELETE /admin/users/:id" do
    it "lets a platform admin remove another user" do
      admin = create(:user, :platform_admin)
      other = create(:user)
      sign_in admin

      expect {
        delete admin_user_path(other)
      }.to change(User, :count).by(-1)
      expect(response).to redirect_to(admin_users_path)
    end

    it "prevents destroying the last platform admin" do
      admin = create(:user, :platform_admin)
      sign_in admin

      expect {
        delete admin_user_path(admin)
      }.not_to change(User, :count)
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      other = create(:user)
      sign_in user

      expect {
        delete admin_user_path(other)
      }.not_to change(User, :count)
      expect(response).to have_http_status(:not_found)
    end
  end
end
