require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "is accessible without authentication" do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "shows sign in/up links when not authenticated" do
      get root_path

      expect(response.body).to include("Sign in")
      expect(response.body).to include("Sign up")
    end

    it "shows a link to the user's bands when authenticated" do
      user = create(:user)
      sign_in user

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Your bands")
    end
  end
end
