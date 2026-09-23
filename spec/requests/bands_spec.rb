require "rails_helper"

RSpec.describe "Bands", type: :request do
  describe "GET /bands/new" do
    it "redirects to sign in when unauthenticated" do
      get new_band_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "POST /bands" do
    it "requires authentication" do
      post bands_path, params: { band: { name: "The Testers" } }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "creates a pending band and makes the creator its administrator" do
      user = create(:user)
      sign_in user

      expect {
        post bands_path, params: { band: { name: "The Testers" } }
      }.to change(Band, :count).by(1)

      band = Band.last
      expect(band.status).to eq("pending")
      expect(band.band_memberships.find_by(user: user).role).to eq("administrator")
      expect(response).to redirect_to(band_path(band))
    end

    it "does not create a band or membership when validation fails" do
      user = create(:user)
      sign_in user

      expect {
        post bands_path, params: { band: { name: "" } }
      }.to change(Band, :count).by(0).and(change(BandMembership, :count).by(0))

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not create a band when platform-wide sign-ups are disabled" do
      user = create(:user)
      sign_in user
      PlatformSetting.current.update!(band_signups_enabled: false)

      expect {
        post bands_path, params: { band: { name: "The Testers" } }
      }.not_to change(Band, :count)

      expect(response).to redirect_to(bands_path)
    end
  end

  describe "GET /bands/search" do
    let(:artist) do
      SpotifyClient::ArtistResult.new(
        spotify_id: "artist123", name: "Daft Punk",
        image_url: "https://example.com/artist.jpg",
        spotify_url: "https://open.spotify.com/artist/artist123"
      )
    end

    it "returns matching artists for a signed-in user" do
      sign_in create(:user)
      allow_any_instance_of(SpotifyClient).to receive(:search_artists).and_return([ artist ])

      get search_bands_path, params: { q: "Daft Punk" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.first).to include(
        "name" => "Daft Punk",
        "spotify_url" => "https://open.spotify.com/artist/artist123"
      )
    end

    # Otherwise this is an open proxy to Spotify's API for anyone at all.
    it "requires authentication" do
      get search_bands_path, params: { q: "Daft Punk" }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "returns no results when platform-wide sign-ups are disabled" do
      sign_in create(:user)
      PlatformSetting.current.update!(band_signups_enabled: false)
      allow_any_instance_of(SpotifyClient).to receive(:search_artists).and_return([ artist ])

      get search_bands_path, params: { q: "Daft Punk" }

      expect(response.parsed_body).to eq([])
    end

    it "reports a bad gateway when Spotify is unavailable" do
      sign_in create(:user)
      allow_any_instance_of(SpotifyClient).to receive(:search_artists).and_raise(SpotifyClient::Error)

      get search_bands_path, params: { q: "Daft Punk" }

      expect(response).to have_http_status(:bad_gateway)
    end
  end

  describe "POST /bands with a Spotify photo" do
    let(:image) do
      RemoteImageFetcher::Result.new(
        io: StringIO.new(file_fixture("band_photo.png").read),
        filename: "artist.png", content_type: "image/png"
      )
    end

    it "attaches the artist photo fetched from Spotify" do
      sign_in create(:user)
      allow_any_instance_of(RemoteImageFetcher).to receive(:call).and_return(image)

      post bands_path, params: {
        band: { name: "The Testers" },
        spotify_image_url: "https://example.com/artist.jpg"
      }

      expect(Band.last.photo).to be_attached
    end

    # A Spotify outage must not cost the user their sign-up.
    it "still creates the band when the photo cannot be fetched" do
      sign_in create(:user)
      allow_any_instance_of(RemoteImageFetcher).to receive(:call).and_raise(RemoteImageFetcher::Error)

      expect {
        post bands_path, params: {
          band: { name: "The Testers" },
          spotify_image_url: "https://example.com/artist.jpg"
        }
      }.to change(Band, :count).by(1)

      expect(Band.last.photo).not_to be_attached
      expect(response).to redirect_to(band_path(Band.last))
    end

    it "does not fetch anything when no Spotify image was chosen" do
      sign_in create(:user)
      expect_any_instance_of(RemoteImageFetcher).not_to receive(:call)

      post bands_path, params: { band: { name: "The Testers" } }

      expect(Band.last.photo).not_to be_attached
    end
  end

  describe "GET /bands/:id" do
    it "allows a band administrator to view their band" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      get band_path(band)

      expect(response).to have_http_status(:ok)
    end

    it "allows a band member to view their band" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      get band_path(band)

      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for a non-member, not 403, to avoid leaking existence" do
      user = create(:user)
      band = create(:band)
      sign_in user

      get band_path(band)

      expect(response).to have_http_status(:not_found)
    end

    it "allows a platform admin to view any band" do
      user = create(:user, :platform_admin)
      band = create(:band)
      sign_in user

      get band_path(band)

      expect(response).to have_http_status(:ok)
    end

    # The overview used to open with four zeros and nothing to act on. It
    # now leads with whatever the band most needs to do next, in the order
    # the work has to happen: music, then payments, then an audience.
    describe "the overview's next step" do
      def administrator_of(band)
        admin = create(:user)
        create(:band_membership, :administrator, band: band, user: admin)
        sign_in admin
        admin
      end

      def heading
        Nokogiri::HTML(response.body).css("h3").first.text.strip
      end

      it "asks a new band for a release first" do
        band = create(:band)
        administrator_of(band)

        get band_path(band)

        expect(heading).to eq("Add your first release")
      end

      # Without Stripe the band cannot be paid at all, so it outranks
      # anything to do with audience.
      it "asks for Stripe once there is music" do
        band = create(:band)
        create(:album, band: band)
        administrator_of(band)

        get band_path(band)

        expect(heading).to eq("Connect Stripe to get paid")
      end

      it "asks for a post once music and payments are in place" do
        band = create(:band, :payouts_ready)
        create(:album, band: band)
        administrator_of(band)

        get band_path(band)

        expect(heading).to eq("Write to your followers")
      end

      # An order that has been paid for outranks the rest: someone is
      # waiting on a parcel.
      it "surfaces orders waiting to be sent" do
        band = create(:band, :payouts_ready)
        create(:album, band: band)
        create(:post, band: band)
        create(:order, :paid, band: band)
        administrator_of(band)

        get band_path(band)

        expect(heading).to eq("You have orders to send")
      end

      it "says so when nothing is outstanding" do
        band = create(:band, :payouts_ready)
        create(:album, band: band)
        create(:post, band: band)
        administrator_of(band)

        get band_path(band)

        expect(heading).to eq("Everything's set up")
      end

      # A plain member cannot act on any of these, so telling them
      # everything is set up would assert something this panel never
      # checked on their behalf.
      it "does not claim the band is set up to a plain member" do
        band = create(:band)
        member = create(:user)
        create(:band_membership, band: band, user: member, role: :member)
        sign_in member

        get band_path(band)

        expect(response.body).not_to include("Everything's set up")
        expect(response.body).to include("administrator's job")
      end
    end

    describe "the First Steps tab" do
      def administrator_of(band)
        admin = create(:user)
        create(:band_membership, :administrator, band: band, user: admin)
        sign_in admin
      end

      def page
        Nokogiri::HTML(response.body)
      end

      it "shows a new band's progress and every step as pending" do
        band = create(:band)
        administrator_of(band)

        get band_path(band, tab: "first_steps")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("0 of 4")
        expect(page.css("h4").map { |h| h.text.strip }).to eq([
          "Get approved by SceneCore", "Add your first release",
          "Connect Stripe to get paid", "Write to your followers"
        ])
        expect(page.css("[data-step]").map { |s| s["data-status"] }).to all(eq("pending"))
      end

      it "counts what the band has already done" do
        band = create(:band, :approved, :payouts_ready)
        create(:album, band: band)
        administrator_of(band)

        get band_path(band, tab: "first_steps")

        expect(response.body).to include("3 of 4")
        expect(page.css("a").map { |a| a.text.strip }).to include("New post")
        expect(page.css("a").map { |a| a.text.strip }).not_to include("Add album", "Set up payments")
      end

      it "shows the remaining count beside the tab and hides it once everything is done" do
        band = create(:band)
        administrator_of(band)

        get band_path(band)
        tab = page.at_css("a[href='#{band_path(band, tab: 'first_steps')}']")
        expect(tab.text.squish).to eq("First Steps 4")

        band.update!(status: :approved, stripe_connect_status: :active, stripe_connect_account_id: "acct_done")
        create(:album, band: band)
        create(:post, band: band)

        get band_path(band)
        tab = page.at_css("a[href='#{band_path(band, tab: 'first_steps')}']")
        expect(tab.text.squish).to eq("First Steps")
      end

      # The checklist is band administration, so a plain member neither sees
      # the tab nor can open it by URL.
      it "is not available to a plain member" do
        band = create(:band)
        member = create(:user)
        create(:band_membership, band: band, user: member, role: :member)
        sign_in member

        get band_path(band)
        expect(response.body).not_to include("First Steps")

        get band_path(band, tab: "first_steps")
        expect(response).to redirect_to(root_path)
      end
    end

    describe "the overview's figures" do
      it "shows shares of the membership only once there are members" do
        band = create(:band)
        admin = create(:user)
        create(:band_membership, :administrator, band: band, user: admin)
        create(:membership, band: band, level: :fan)
        sign_in admin

        get band_path(band)

        expect(response.body).to include("of members")
      end

      # Four "0%" readings say nothing, so a band with no members sees
      # plain counts instead.
      it "omits the shares while the band has no members" do
        band = create(:band)
        admin = create(:user)
        create(:band_membership, :administrator, band: band, user: admin)
        sign_in admin

        get band_path(band)

        expect(response.body).not_to include("of members")
      end

      # The previous hand-rolled bars were sized as a percentage of the
      # tallest, so an empty history rendered six invisible bars under a
      # row of stray labels.
      it "explains an empty membership history rather than drawing nothing" do
        band = create(:band)
        admin = create(:user)
        create(:band_membership, :administrator, band: band, user: admin)
        sign_in admin

        get band_path(band)

        expect(response.body).to include("No members yet")
      end

      it "quotes the commission from the platform setting" do
        band = create(:band)
        admin = create(:user)
        create(:band_membership, :administrator, band: band, user: admin)
        sign_in admin

        get band_path(band)

        expect(response.body).to include("#{PlatformSetting.current.membership_fee_percentage}%")
      end
    end

    describe "tabs" do
      def sign_in_as_member(band)
        user = create(:user)
        create(:band_membership, band: band, user: user)
        sign_in user
        user
      end

      it "opens on the overview" do
        band = create(:band)
        sign_in_as_member(band)

        get band_path(band)

        expect(Nokogiri::HTML(response.body).css("a[aria-current='page']").text).to include("Overview")
      end

      # The tab comes from the query string, so an unknown value falls back
      # rather than reaching a render call with whatever was passed.
      it "falls back to the overview for an unknown tab" do
        band = create(:band)
        sign_in_as_member(band)

        get band_path(band, tab: "nope")

        expect(response).to have_http_status(:ok)
        expect(Nokogiri::HTML(response.body).css("a[aria-current='page']").text).to include("Overview")
      end

      it "shows albums on the music tab and not on the others" do
        band = create(:band)
        create(:album, band: band, title: "Only Album")
        sign_in_as_member(band)

        get band_path(band, tab: "music")
        expect(response.body).to include("Only Album")

        get band_path(band, tab: "posts")
        expect(response.body).not_to include("Only Album")
      end

      it "shows posts on the posts tab" do
        band = create(:band)
        create(:post, band: band, title: "Only Post")
        sign_in_as_member(band)

        get band_path(band, tab: "posts")

        expect(response.body).to include("Only Post")
      end

      it "shows events on the shows tab" do
        band = create(:band)
        create(:event, band: band, title: "Only Show")
        sign_in_as_member(band)

        get band_path(band, tab: "shows")

        expect(response.body).to include("Only Show")
      end

      it "groups polls and core sessions under community" do
        band = create(:band)
        create(:poll, band: band, question: "Only Poll")
        create(:core_session, band: band, title: "Only Session")
        sign_in_as_member(band)

        get band_path(band, tab: "community")

        expect(response.body).to include("Only Poll")
        expect(response.body).to include("Only Session")
      end

      it "counts each tab's records beside its label" do
        band = create(:band)
        2.times { create(:album, band: band) }
        sign_in_as_member(band)

        get band_path(band)

        music_tab = Nokogiri::HTML(response.body).css("a[href*='tab=music']").text

        expect(music_tab).to include("2")
      end

      # An empty tab explains what the section is for; the action to fill it
      # is already above.
      it "explains an empty tab rather than rendering nothing" do
        band = create(:band)
        sign_in_as_member(band)

        get band_path(band, tab: "music")

        expect(response.body).to include("No albums yet")
      end

      # The manage tabs open in the same panel rather than navigating away,
      # so the band stays in one place.
      describe "manage tabs" do
        def sign_in_as_administrator(band)
          admin = create(:user)
          create(:band_membership, :administrator, band: band, user: admin)
          sign_in admin
          admin
        end

        it "shows the band profile in the panel" do
          band = create(:band, description: "A description")
          sign_in_as_administrator(band)

          get band_path(band, tab: "profile")

          expect(response.body).to include("A description")
        end

        it "shows band members in the panel" do
          band = create(:band)
          admin = sign_in_as_administrator(band)

          get band_path(band, tab: "members")

          expect(response.body).to include(admin.name)
        end

        it "shows supporters in the panel" do
          band = create(:band)
          supporter = create(:user, name: "Supporting Fan")
          create(:membership, band: band, user: supporter, level: :supporter)
          sign_in_as_administrator(band)

          get band_path(band, tab: "supporters")

          expect(response.body).to include("Supporting Fan")
        end

        it "shows products in the panel" do
          band = create(:band)
          create(:product, band: band, name: "Only Product")
          sign_in_as_administrator(band)

          get band_path(band, tab: "products")

          expect(response.body).to include("Only Product")
        end

        it "shows the payments status in the panel" do
          band = create(:band)
          sign_in_as_administrator(band)

          get band_path(band, tab: "payments")

          expect(response.body).to include("haven&#39;t connected Stripe yet")
        end

        # These tabs carry the band's own money and membership records, so a
        # plain member must not reach them by editing the query string.
        it "refuses a plain member on every manage tab" do
          band = create(:band)
          member = create(:user)
          create(:band_membership, band: band, user: member, role: :member)
          sign_in member

          BandsController::MANAGE_TABS.each do |tab|
            get band_path(band, tab: tab)

            expect(response).to have_http_status(:found), "#{tab} was reachable"
          end
        end

        it "does not offer the manage tabs to a plain member" do
          band = create(:band)
          member = create(:user)
          create(:band_membership, band: band, user: member, role: :member)
          sign_in member

          get band_path(band)

          labels = Nokogiri::HTML(response.body).css("a[href*='tab=']").map(&:text)

          expect(labels.join).not_to include("Payments")
        end

        # A platform admin manages the rest of the panel, but the band's
        # Stripe account is the band's own money (docs/permissions.md).
        it "keeps the payments tab from a platform admin who is not the band's administrator" do
          band = create(:band)
          sign_in create(:user, :platform_admin)

          get band_path(band)

          labels = Nokogiri::HTML(response.body).css("a[href*='tab=']").map(&:text)
          expect(labels.join).to include("Profile")
          expect(labels.join).not_to include("Payments")

          get band_path(band, tab: "payments")

          expect(response).to redirect_to(root_path)
        end

        # Payments is the one tab that needs attention before it is opened,
        # since nothing else on the panel says the band cannot take money.
        it "flags payments while the band cannot take money" do
          band = create(:band)
          sign_in_as_administrator(band)

          get band_path(band)

          payments_tab = Nokogiri::HTML(response.body).css("a[href*='tab=payments']").first

          expect(payments_tab["class"]).to include("yellow")
        end

        it "stops flagging payments once the account is active" do
          band = create(:band, stripe_connect_status: :active, stripe_connect_account_id: "acct_1")
          sign_in_as_administrator(band)

          get band_path(band)

          payments_tab = Nokogiri::HTML(response.body).css("a[href*='tab=payments']").first

          expect(payments_tab["class"]).not_to include("yellow")
        end
      end

      # Each tab carries the action for its own content, so a band does not
      # meet eleven buttons before finding what it came for.
      it "offers the add action on the tab it belongs to" do
        band = create(:band)
        sign_in_as_member(band)

        get band_path(band, tab: "music")
        expect(response.body).to include(new_band_album_path(band))

        get band_path(band, tab: "shows")
        expect(response.body).not_to include(new_band_album_path(band))
      end
    end

    # The panel used to count tracks per album. Albums link out to Spotify
    # now, so the page has no reason to touch that table at all.
    it "does not query tracks" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      3.times { create(:album, band: band) }
      sign_in user

      track_queries = 0
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        track_queries += 1 if payload[:sql].include?('"tracks"') && payload[:name] != "SCHEMA"
      end
      get band_path(band)
      ActiveSupport::Notifications.unsubscribe(subscriber)

      expect(track_queries).to eq(0)
    end

    it "shows membership counts per level to a band member" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      create(:membership, band: band, level: :fan)
      create(:membership, band: band, level: :fan)
      create(:membership, band: band, level: :supporter)
      create(:membership, band: band, level: :core_member)
      sign_in user

      get band_path(band)

      expect(response.body).to include("Fans")
      expect(response.body).to include("Supporters")
      expect(response.body).to include("Core Members")
    end

    it "does not count a paused or cancelled membership toward the level totals" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      create(:membership, band: band, level: :fan, status: :active)
      create(:membership, band: band, level: :fan, status: :cancelled)
      sign_in user

      get band_path(band)

      fans_card = Nokogiri::HTML(response.body).css("[data-metric='fans']").first

      expect(fans_card.text).to include("1")
      expect(fans_card.text).not_to include("2")
    end

    it "does not show membership counts to an anonymous or unrelated visitor" do
      band = create(:band)
      create(:membership, band: band, level: :fan)

      get band_path(band)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the plan distribution percentage and estimated monthly revenue" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      create(:membership, band: band, level: :fan)
      create(:membership, band: band, level: :fan)
      create(:membership, band: band, level: :fan)
      create(:membership, band: band, level: :supporter)
      sign_in user

      get band_path(band)

      # 3 fans + 1 supporter = 4 total; fans are 75%
      expect(response.body).to include("75%")
      # (3 * $3.00) + (1 * $5.00) = $14.00
      expect(response.body).to include("$14.00")
    end

    it "shows how many new members joined in each of the last 6 months" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      create(:membership, band: band, level: :fan, created_at: 2.months.ago.beginning_of_month + 1.day)
      sign_in user

      get band_path(band)

      expect(response.body).to include("New members")
      expect(response.body).to include("Last 6 months")
      expect(response.body).to include(2.months.ago.strftime("%b"))
    end
  end

  describe "band isolation" do
    it "prevents an administrator of one band from editing another band, even by crafting the URL" do
      band_a_admin = create(:user)
      band_a = create(:band)
      create(:band_membership, :administrator, band: band_a, user: band_a_admin)

      band_b = create(:band, name: "Band B")

      sign_in band_a_admin

      get edit_band_path(band_b)
      expect(response).to have_http_status(:not_found)

      patch band_path(band_b), params: { band: { name: "Hijacked" } }
      expect(response).to have_http_status(:not_found)
      expect(band_b.reload.name).to eq("Band B")
    end

    it "prevents a band administrator from approving or rejecting their own band" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      patch approve_band_path(band)

      expect(band.reload.status).to eq("pending")
    end
  end

  describe "PATCH /bands/:id (photo upload)" do
    it "attaches a valid photo" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      photo = fixture_file_upload("band_photo.png", "image/png")

      patch band_path(band), params: { band: { photo: photo } }

      expect(response).to redirect_to(band_path(band))
      expect(band.reload.photo).to be_attached
    end

    it "rejects a non-image file and re-renders the form without erroring" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      invalid_file = fixture_file_upload("invalid_photo.txt", "text/plain")

      patch band_path(band), params: { band: { photo: invalid_file } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("must be a PNG, JPEG, or WebP image")
      expect(band.reload.photo).not_to be_attached
    end
  end

  describe "PATCH /bands/:id (social links)" do
    it "updates the band's social links" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      patch band_path(band), params: { band: { spotify_url: "https://open.spotify.com/artist/1" } }

      expect(response).to redirect_to(band_path(band))
      expect(band.reload.spotify_url).to eq("https://open.spotify.com/artist/1")
    end

    it "rejects an invalid social link URL" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      patch band_path(band), params: { band: { spotify_url: "not a url" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("must be a valid URL")
    end
  end

  describe "PATCH /bands/:id (category)" do
    it "allows the band's administrator to set the band's category" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      category = create(:category, name: "Rock")
      sign_in user

      patch band_path(band), params: { band: { category_id: category.id } }

      expect(band.reload.category).to eq(category)
    end

    it "allows clearing the band's category" do
      user = create(:user)
      category = create(:category)
      band = create(:band, category: category)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      patch band_path(band), params: { band: { category_id: "" } }

      expect(band.reload.category).to be_nil
    end
  end

  describe "PATCH /bands/:id/approve" do
    it "allows a platform admin to approve a band" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      sign_in admin

      patch approve_band_path(band)

      expect(band.reload.status).to eq("approved")
    end

    it "does not allow a regular user to approve a band" do
      user = create(:user)
      band = create(:band)
      sign_in user

      patch approve_band_path(band)

      expect(band.reload.status).to eq("pending")
    end

    it "requires authentication" do
      band = create(:band)

      patch approve_band_path(band)

      expect(response).to redirect_to(new_user_session_path)
      expect(band.reload.status).to eq("pending")
    end

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      sign_in admin

      expect {
        patch approve_band_path(band)
      }.to change(AdminActionLog, :count).by(1)

      log = AdminActionLog.last
      expect(log.actor).to eq(admin)
      expect(log.action).to eq("approve_band")
      expect(log.subject).to eq(band)
    end
  end

  describe "PATCH /bands/:id/reject" do
    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      band = create(:band)
      sign_in admin

      expect {
        patch reject_band_path(band)
      }.to change(AdminActionLog, :count).by(1)

      expect(AdminActionLog.last.action).to eq("reject_band")
    end
  end

  describe "PATCH /bands/:id/suspend" do
    it "allows a platform admin to suspend an approved band" do
      admin = create(:user, :platform_admin)
      band = create(:band, :approved)
      sign_in admin

      patch suspend_band_path(band)

      expect(band.reload.status).to eq("suspended")
    end

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      band = create(:band, :approved)
      sign_in admin

      expect {
        patch suspend_band_path(band)
      }.to change(AdminActionLog, :count).by(1)

      expect(AdminActionLog.last.action).to eq("suspend_band")
    end

    it "does not allow a regular user to suspend a band" do
      user = create(:user)
      band = create(:band, :approved)
      sign_in user

      patch suspend_band_path(band)

      expect(band.reload.status).to eq("approved")
    end

    it "does not allow the band's own administrator to suspend it" do
      user = create(:user)
      band = create(:band, :approved)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      patch suspend_band_path(band)

      expect(band.reload.status).to eq("approved")
    end

    it "requires authentication" do
      band = create(:band, :approved)

      patch suspend_band_path(band)

      expect(response).to redirect_to(new_user_session_path)
      expect(band.reload.status).to eq("approved")
    end

    it "makes the band's public page inaccessible" do
      admin = create(:user, :platform_admin)
      band = create(:band, :approved)
      sign_in admin

      patch suspend_band_path(band)

      get public_band_path(band.slug)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /bands/:id/feature" do
    it "allows a platform admin to feature an approved band" do
      admin = create(:user, :platform_admin)
      band = create(:band, :approved)
      sign_in admin

      patch feature_band_path(band)

      expect(band.reload).to be_featured
    end

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      band = create(:band, :approved)
      sign_in admin

      expect {
        patch feature_band_path(band)
      }.to change(AdminActionLog, :count).by(1)

      expect(AdminActionLog.last.action).to eq("feature_band")
    end

    it "unfeatures the previously featured band" do
      admin = create(:user, :platform_admin)
      previous = create(:band, :approved, featured: true)
      band = create(:band, :approved)
      sign_in admin

      patch feature_band_path(band)

      expect(previous.reload).not_to be_featured
      expect(band.reload).to be_featured
    end

    it "shows the featured band on the home page" do
      admin = create(:user, :platform_admin)
      create(:band, :approved, name: "Newer Band")
      band = create(:band, :approved, name: "Pinned Band")
      sign_in admin

      patch feature_band_path(band)
      get root_path

      expect(response.body).to include("Pinned Band")
      expect(response.body).not_to include("Newer Band")
    end

    it "does not allow a regular user to feature a band" do
      user = create(:user)
      band = create(:band, :approved)
      sign_in user

      patch feature_band_path(band)

      expect(band.reload).not_to be_featured
    end

    it "does not allow the band's own administrator to feature it" do
      user = create(:user)
      band = create(:band, :approved)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      patch feature_band_path(band)

      expect(band.reload).not_to be_featured
    end

    it "requires authentication" do
      band = create(:band, :approved)

      patch feature_band_path(band)

      expect(response).to redirect_to(new_user_session_path)
      expect(band.reload).not_to be_featured
    end
  end

  describe "PATCH /bands/:id/unfeature" do
    it "allows a platform admin to unfeature a band" do
      admin = create(:user, :platform_admin)
      band = create(:band, :approved, featured: true)
      sign_in admin

      patch unfeature_band_path(band)

      expect(band.reload).not_to be_featured
    end

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      band = create(:band, :approved, featured: true)
      sign_in admin

      expect {
        patch unfeature_band_path(band)
      }.to change(AdminActionLog, :count).by(1)

      expect(AdminActionLog.last.action).to eq("unfeature_band")
    end

    it "does not allow a regular user to unfeature a band" do
      user = create(:user)
      band = create(:band, :approved, featured: true)
      sign_in user

      patch unfeature_band_path(band)

      expect(band.reload).to be_featured
    end
  end

  describe "PATCH /bands/:id/reactivate" do
    it "allows a platform admin to reactivate a suspended band" do
      admin = create(:user, :platform_admin)
      band = create(:band, :suspended)
      sign_in admin

      patch reactivate_band_path(band)

      expect(band.reload.status).to eq("approved")
    end

    it "records an admin action log" do
      admin = create(:user, :platform_admin)
      band = create(:band, :suspended)
      sign_in admin

      expect {
        patch reactivate_band_path(band)
      }.to change(AdminActionLog, :count).by(1)

      expect(AdminActionLog.last.action).to eq("reactivate_band")
    end

    it "does not allow a regular user to reactivate a band" do
      user = create(:user)
      band = create(:band, :suspended)
      sign_in user

      patch reactivate_band_path(band)

      expect(band.reload.status).to eq("suspended")
    end

    it "requires authentication" do
      band = create(:band, :suspended)

      patch reactivate_band_path(band)

      expect(response).to redirect_to(new_user_session_path)
      expect(band.reload.status).to eq("suspended")
    end
  end
end
