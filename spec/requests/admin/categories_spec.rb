require "rails_helper"

RSpec.describe "Admin::Categories", type: :request do
  describe "GET /admin/categories" do
    it "lists root categories with their subcategories for a platform admin" do
      admin = create(:user, :platform_admin)
      root = create(:category, name: "Rock")
      create(:category, name: "Thrash Metal", parent: root)
      sign_in admin

      get admin_categories_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Rock")
      expect(response.body).to include("Thrash Metal")
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      sign_in user

      get admin_categories_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get admin_categories_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "POST /admin/categories" do
    it "creates a root category" do
      admin = create(:user, :platform_admin)
      sign_in admin

      expect {
        post admin_categories_path, params: { category: { name: "Rock" } }
      }.to change(Category, :count).by(1)

      expect(Category.last.parent).to be_nil
      expect(response).to redirect_to(admin_categories_path)
    end

    it "creates a subcategory under a root category" do
      admin = create(:user, :platform_admin)
      root = create(:category, name: "Rock")
      sign_in admin

      post admin_categories_path, params: { category: { name: "Thrash Metal", parent_id: root.id } }

      expect(Category.last.parent).to eq(root)
    end

    it "does not create a category without a name" do
      admin = create(:user, :platform_admin)
      sign_in admin

      expect {
        post admin_categories_path, params: { category: { name: "" } }
      }.not_to change(Category, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not allow a regular user to create a category" do
      user = create(:user)
      sign_in user

      expect {
        post admin_categories_path, params: { category: { name: "Rock" } }
      }.not_to change(Category, :count)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /admin/categories/:id" do
    it "updates a category's name" do
      admin = create(:user, :platform_admin)
      category = create(:category, name: "Old Name")
      sign_in admin

      patch admin_category_path(category), params: { category: { name: "New Name" } }

      expect(category.reload.name).to eq("New Name")
    end
  end

  describe "DELETE /admin/categories/:id" do
    it "deletes a category with no subcategories" do
      admin = create(:user, :platform_admin)
      category = create(:category)
      sign_in admin

      expect {
        delete admin_category_path(category)
      }.to change(Category, :count).by(-1)
    end

    it "does not delete a category that has subcategories" do
      admin = create(:user, :platform_admin)
      root = create(:category)
      create(:category, parent: root)
      sign_in admin

      expect {
        delete admin_category_path(root)
      }.not_to change(Category, :count)

      expect(response).to redirect_to(admin_categories_path)
    end

    it "nullifies bands' category when the category is deleted" do
      admin = create(:user, :platform_admin)
      category = create(:category)
      band = create(:band, category: category)
      sign_in admin

      delete admin_category_path(category)

      expect(band.reload.category).to be_nil
    end
  end
end
