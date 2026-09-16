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

      it "shows a link to the public band directory when not authenticated" do
        get root_path

        expect(response.body).to include(discover_bands_path)
      end

      it "shows a link to the public band directory when authenticated" do
        user = create(:user)
        sign_in user

        get root_path

        expect(response.body).to include(discover_bands_path)
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

      it "shows up to 3 published albums from any approved band" do
        create(:band, :approved, name: "Farscape")
        band_two = create(:band, :approved, name: "Other Band")
        create(:album, :published, band: band_two, title: "Great Album")

        get root_path

        expect(response.body).to include("Feature Music Albums")
        expect(response.body).to include("Great Album")
        expect(response.body).to include("Other Band")
      end

      it "shows the album's Spotify cover thumbnail when no cover was uploaded" do
        band = create(:band, :approved, name: "Farscape")
        create(:album, :published, band: band, title: "Discovery", spotify_cover_url: "https://i.scdn.co/image/discovery-cover.jpg")

        get root_path

        expect(response.body).to include("https://i.scdn.co/image/discovery-cover.jpg")
      end

      it "does not show a draft album" do
        band = create(:band, :approved, name: "Farscape")
        create(:album, band: band, title: "Secret Album")

        get root_path

        expect(response.body).not_to include("Secret Album")
      end

      it "does not show a published album from a non-approved band" do
        create(:band, :approved, name: "Farscape")
        other_band = create(:band, name: "Pending Band Two")
        create(:album, :published, band: other_band, title: "Hidden Album")

        get root_path

        expect(response.body).not_to include("Hidden Album")
      end

      it "does not show the albums section when there are no published albums" do
        create(:band, :approved, name: "Farscape")

        get root_path

        expect(response.body).not_to include("Feature Music Albums")
      end

      it "shows up to 3 published public posts from any approved band" do
        band = create(:band, :approved, name: "Farscape")
        create(:post, :published, band: band, title: "On tour", body: "We are hitting the road next month.")

        get root_path

        expect(response.body).to include("Latest from the bands")
        expect(response.body).to include("On tour")
        expect(response.body).to include("We are hitting the road next month.")
        expect(response.body).to include("Farscape")
      end

      it "links each latest post to the band's public page, anchored at the post" do
        band = create(:band, :approved, name: "Farscape")
        post_record = create(:post, :published, band: band, title: "On tour")

        get root_path

        expect(response.body).to include("#{public_band_path(band.slug)}#post-#{post_record.id}")
      end

      it "does not show a draft post" do
        band = create(:band, :approved, name: "Farscape")
        create(:post, band: band, title: "Secret News")

        get root_path

        expect(response.body).not_to include("Secret News")
      end

      it "does not show a followers-only post" do
        band = create(:band, :approved, name: "Farscape")
        create(:post, :published, :followers_only, band: band, title: "Followers News")

        get root_path

        expect(response.body).not_to include("Followers News")
      end

      it "does not show a published post from a non-approved band" do
        create(:band, :approved, name: "Farscape")
        other_band = create(:band, name: "Pending Band Two")
        create(:post, :published, band: other_band, title: "Hidden News")

        get root_path

        expect(response.body).not_to include("Hidden News")
      end

      it "does not show the latest posts section when there are none" do
        create(:band, :approved, name: "Farscape")

        get root_path

        expect(response.body).not_to include("Latest from the bands")
      end
    end
  end

  describe "static pages" do
    { "/how-it-works" => "How it works", "/contact" => "Contact", "/support" => "Support" }.each do |path, heading|
      it "serves #{path} to a visitor" do
        get path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(heading)
      end
    end
  end

  describe "footer" do
    it "shows the links to a visitor, including Subscribe" do
      get root_path

      expect(response.body).to include("How it Works")
      expect(response.body).to include(contact_path)
      expect(response.body).to include(support_path)
      expect(response.body).to include(">Subscribe</a>")
    end

    it "hides Subscribe from a signed-in user" do
      sign_in create(:user)

      get root_path

      expect(response.body).to include("How it Works")
      expect(response.body).not_to include(">Subscribe</a>")
    end
  end
end
