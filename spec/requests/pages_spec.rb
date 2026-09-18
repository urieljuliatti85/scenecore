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

      it "keeps primary and account actions inside one desktop navigation" do
        admin = create(:user, :platform_admin)
        sign_in admin

        get root_path

        navigation = Nokogiri::HTML(response.body).at_css("#desktop-nav")

        expect(navigation).to be_present
        expect(navigation.at_css("a[href='#{discover_bands_path}']")).to be_present
        expect(navigation.at_css("a[href='#{bands_path}']")).to be_present
        expect(navigation.at_css("a[href='#{admin_root_path}']")).to be_present
        expect(navigation.at_css("a[href='#{profile_path}']")).to be_present
        expect(navigation.at_css("a[href='#{cart_path}']")).to be_present
        expect(navigation.at_css("a[href='#{tickets_path}']")).to be_present
        expect(navigation.at_css("form[action='#{destroy_user_session_path}']")).to be_present
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
        expect(response.body).to include("Posts")
        expect(response.body).to include("Tickets")
      end

      # Music and Posts have no global index — each band's page is where
      # that content lives — so on the home page they point at the band
      # directory rather than rendering as dead cards.
      it "links the Music and Posts cards to the band directory" do
        create(:band, :approved, name: "Farscape")

        get root_path

        expect(response.body).to include("href=\"#{discover_bands_path}\"")
      end

      it "sends a signed-out visitor from Subscriptions to the band directory" do
        create(:band, :approved, name: "Farscape")

        get root_path

        expect(response.body).not_to include("href=\"#{subscriptions_path}\"")
      end

      it "sends a signed-in user from Subscriptions to their own subscriptions" do
        create(:band, :approved, name: "Farscape")
        sign_in create(:user)

        get root_path

        expect(response.body).to include("href=\"#{subscriptions_path}\"")
      end

      it "links Exclusive Content to band discovery and keeps Tickets disabled" do
        create(:band, :approved, name: "Farscape")

        get root_path

        doc = Nokogiri::HTML(response.body)
        exclusive_content = doc.xpath("//a[.//span[normalize-space()='Exclusive Content']]")

        expect(exclusive_content.first["href"]).to eq(discover_bands_path)
        expect(response.body).to include("Soon")
        expect(response.body).to include("cursor-not-allowed")
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

  describe "GET /about" do
    it "is reachable without signing in" do
      get about_path

      expect(response).to have_http_status(:ok)
    end

    it "leads with the product promise" do
      get about_path

      expect(Nokogiri::HTML(response.body).css("h1").text).to include("Your band. Your fans. Your home.")
    end

    # The page states what SceneCore is not, which is the part most likely
    # to be softened into a claim the platform does not stand behind.
    it "says it does not replace streaming" do
      get about_path

      expect(response.body).to include("Not a streaming replacement")
    end

    # Quoted from the same constants and ADRs the How it works page uses, so
    # the two pages can never disagree about what a band keeps.
    it "quotes the same revenue splits as How it works" do
      get about_path

      expect(response.body).to include("85% of memberships")
      expect(response.body).to include("90% of store sales")
      expect(response.body).to include("90% of paid tickets")
    end

    it "summarizes the live product from discovery through ticketing" do
      get about_path

      expect(response.body).to include("Music and discovery")
      expect(response.body).to include("Memberships")
      expect(response.body).to include("Store")
      expect(response.body).to include("Events and tickets")
      expect(response.body).to include("Platform governance")
    end

    it "documents the public technical stack and delivery pipeline" do
      get about_path

      expect(response.body).to include("Ruby 3.3 and Rails 8.1")
      expect(response.body).to include("PostgreSQL 16")
      expect(response.body).to include("GitHub Actions")
      expect(response.body).to include("Railway")
    end

    it "distinguishes live capabilities from the next increments" do
      get about_path

      expect(response.body).to include("Live now")
      expect(response.body).to include("Next increments")
      expect(response.body).to include("Membership discounts and priority access for tickets")
    end

    it "is linked from the header nav and the footer" do
      get root_path

      doc = Nokogiri::HTML(response.body)

      expect(doc.css("#desktop-nav a[href='#{about_path}']")).to be_present
      expect(doc.css("footer a[href='#{about_path}']")).to be_present
    end

    it "marks itself as the current page in the nav" do
      get about_path

      current = Nokogiri::HTML(response.body).css("#desktop-nav a[aria-current='page']")

      expect(current.text).to include("About")
    end
  end

  describe "GET /how-it-works" do
    it "is reachable without signing in" do
      get how_it_works_path

      expect(response).to have_http_status(:ok)
    end

    it "lists every membership level with its promise" do
      get how_it_works_path

      expect(response.body).to include("Fan")
      expect(response.body).to include("Supporter")
      expect(response.body).to include("Core Member")
      expect(response.body).to include("Become part of the band&#39;s core group.")
    end

    # Prices render from the same constant Stripe charges against, so the
    # page can never quote a figure the platform does not actually bill.
    it "quotes the prices that memberships actually cost" do
      get how_it_works_path

      Membership::PRICES_IN_CENTS.each_value do |cents|
        expect(response.body).to include("$#{cents / 100}")
      end
    end

    it "states both revenue splits and that bands pay nothing to join" do
      get how_it_works_path

      expect(response.body).to include("85% of memberships")
      expect(response.body).to include("90% of store sales")
      expect(response.body).to include("Creating a band page is free")
    end

    # The two rates differ deliberately (ADR-007/ADR-008), so the page must
    # quote each one rather than collapsing them into a single figure.
    it "quotes each commission rate against the right revenue stream" do
      get how_it_works_path

      expect(response.body).to include("15% to SceneCore")
      expect(response.body).to include("10% to SceneCore")
    end

    # Exactly one plan carries the highlight. Two would leave a visitor with
    # no recommendation, which is the whole point of marking one.
    it "highlights a single membership plan" do
      get how_it_works_path

      doc = Nokogiri::HTML(response.body)

      expect(doc.css("#membership-plans [class*='bg-yellow-400/10']").size).to eq(1)
    end

    it "presents every section in a card" do
      get how_it_works_path

      doc = Nokogiri::HTML(response.body)

      # Two audience cards, three plans, five money-side cards.
      expect(doc.css("div.rounded-3xl").size).to eq(10)
    end
  end
end
