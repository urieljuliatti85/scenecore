require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "is accessible without authentication" do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    context "when there is no approved band" do
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

    context "when there is an approved band" do
      it "shows it as the featured band" do
        create(:band, :approved, name: "Farscape", description: "Thrash metal.")

        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Featured Band")
        expect(response.body).to include("Farscape")
        expect(response.body).to include("Thrash metal.")
      end

      it "does not show a pending or rejected band as featured" do
        create(:band, name: "Pending Band")
        create(:band, :rejected, name: "Rejected Band")

        get root_path

        expect(response.body).not_to include("Featured Band")
      end

      it "shows the coming-soon navigation cards" do
        create(:band, :approved, name: "Farscape")

        get root_path

        expect(response.body).to include("Music")
        expect(response.body).to include("Exclusive Content")
        expect(response.body).to include("Subscriptions")
        expect(response.body).to include("Merchandise")
        expect(response.body).to include("Tickets")
      end

      it "shows social links when present" do
        create(:band, :approved, name: "Farscape", spotify_url: "https://open.spotify.com/artist/1")

        get root_path

        expect(response.body).to include("https://open.spotify.com/artist/1")
      end

      it "does not show social link icons when none are set" do
        create(:band, :approved, name: "Farscape")

        get root_path

        expect(response.body).not_to include("aria-label=\"Spotify\"")
      end
    end
  end
end
