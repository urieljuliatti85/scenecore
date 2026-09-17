require "rails_helper"

RSpec.describe "Public band pages", type: :request do
  describe "GET /discover" do
    it "lists approved bands without authentication" do
      create(:band, :approved, name: "The Testers")

      get discover_bands_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("The Testers")
    end

    it "does not list pending, rejected, or suspended bands" do
      create(:band, name: "Pending Band")
      create(:band, :rejected, name: "Rejected Band")
      create(:band, :suspended, name: "Suspended Band")

      get discover_bands_path

      expect(response.body).not_to include("Pending Band")
      expect(response.body).not_to include("Rejected Band")
      expect(response.body).not_to include("Suspended Band")
    end

    it "links to each band's public page" do
      band = create(:band, :approved, name: "The Testers")

      get discover_bands_path

      expect(response.body).to include(public_band_path(band.slug))
    end

    it "features the most recently added band by default" do
      create(:band, :approved, name: "Older Band", created_at: 2.days.ago)
      create(:band, :approved, name: "Newer Band", created_at: 1.day.ago)

      get discover_bands_path

      body_without_footer = response.body.split("Older Band").first
      expect(body_without_footer).to include("Newer Band")
    end

    it "features the band with the most followers when sorted by followers" do
      popular = create(:band, :approved, name: "Popular Band")
      create_list(:follow, 3, band: popular)
      quiet = create(:band, :approved, name: "Quiet Band")

      get discover_bands_path(sort: "followers")

      body_without_footer = response.body.split("Quiet Band").first
      expect(body_without_footer).to include("Popular Band")
    end

    it "shows the featured band's follower count" do
      band = create(:band, :approved, name: "The Testers")
      create_list(:follow, 2, band: band)

      get discover_bands_path

      expect(response.body).to include("2 followers")
    end

    it "shows the category filter pills" do
      create(:category, name: "Rock")
      create(:category, name: "Jazz")

      get discover_bands_path

      expect(response.body).to include("Rock")
      expect(response.body).to include("Jazz")
    end

    it "filters bands by category" do
      rock = create(:category, name: "Rock")
      jazz = create(:category, name: "Jazz")
      create(:band, :approved, name: "Rock Band", category: rock)
      create(:band, :approved, name: "Jazz Band", category: jazz)

      get discover_bands_path(category_id: rock.id)

      expect(response.body).to include("Rock Band")
      expect(response.body).not_to include("Jazz Band")
    end
  end

  describe "GET /:slug" do
    it "shows an approved band's public page without authentication" do
      band = create(:band, :approved, name: "The Testers", description: "A great band.")

      get public_band_path(band.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("The Testers")
      expect(response.body).to include("A great band.")
    end

    it "shows the band's category when set" do
      category = create(:category, name: "Rock")
      band = create(:band, :approved, name: "The Testers", category: category)

      get public_band_path(band.slug)

      expect(response.body).to include("Rock")
    end

    it "returns 404 for a pending band" do
      band = create(:band, name: "Pending Band")

      get public_band_path(band.slug)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a rejected band" do
      band = create(:band, :rejected, name: "Rejected Band")

      get public_band_path(band.slug)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a nonexistent slug" do
      get public_band_path("no-such-band")

      expect(response).to have_http_status(:not_found)
    end

    it "renders a branded 404 page for a nonexistent slug" do
      get public_band_path("no-such-band")

      expect(response.body).to include("We couldn't find that page")
      expect(response.body).to include(discover_bands_path)
    end

    it "shows the coming-soon navigation cards" do
      band = create(:band, :approved, name: "The Testers")

      get public_band_path(band.slug)

      expect(response.body).to include("Music")
      expect(response.body).to include("Tickets")
    end

    it "links the Music card to the albums section" do
      band = create(:band, :approved)

      get public_band_path(band.slug)

      expect(response.body).to include("#albums")
    end

    it "links the Subscriptions card to the band's subscriptions page" do
      band = create(:band, :approved)

      get public_band_path(band.slug)

      expect(response.body).to include(public_band_subscriptions_path(band.slug))
    end

    it "keeps Tickets disabled with a Soon badge" do
      band = create(:band, :approved)

      get public_band_path(band.slug)

      expect(response.body).to include("Tickets")
      expect(response.body).to include("Soon")
    end

    it "links the Posts card to the posts section" do
      band = create(:band, :approved)
      create(:post, :published, band: band)

      get public_band_path(band.slug)

      expect(response.body).to include("#posts")
    end

    it "does not render the membership plans on the band's main page" do
      band = create(:band, :approved)
      user = create(:user)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).not_to include("Join as Fan")
    end

    it "renders the band's photo as a hero image when attached" do
      band = create(:band, :approved, name: "The Testers")
      band.photo.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/band_photo.png")),
        filename: "band_photo.png",
        content_type: "image/png"
      )

      get public_band_path(band.slug)

      expect(response.body).to include(rails_blob_path(band.photo, only_path: true))
    end

    it "falls back to the gradient background when no photo is attached" do
      band = create(:band, :approved, name: "The Testers")

      get public_band_path(band.slug)

      expect(response.body).to include("bg-gradient-to-br")
    end

    it "shows social links when present" do
      band = create(:band, :approved, name: "The Testers", website_url: "https://the-testers.example.com")

      get public_band_path(band.slug)

      expect(response.body).to include("https://the-testers.example.com")
    end

    it "does not show social link icons when none are set" do
      band = create(:band, :approved, name: "The Testers")

      get public_band_path(band.slug)

      expect(response.body).not_to include("aria-label=\"Website\"")
    end

    it "shows only published albums as cards" do
      band = create(:band, :approved)
      create(:album, :published, band: band, title: "Public Album")
      create(:album, band: band, title: "Secret Album")

      get public_band_path(band.slug)

      expect(response.body).to include("Public Album")
      expect(response.body).not_to include("Secret Album")
    end

    # Albums imported before spotify_id existed have no Spotify link. The
    # card must not offer Spotify and then lead nowhere.
    it "does not offer a Spotify link for an album that has no Spotify id" do
      band = create(:band, :approved)
      create(:album, :published, band: band, title: "Old Import", spotify_id: nil)

      get public_band_path(band.slug)

      expect(response.body).to include("Old Import")
      expect(response.body).not_to include("Listen on Spotify")
    end

    it "sends the album card to the album's own page, not straight to Spotify" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band, title: "Public Album", spotify_id: "4aawyAB9vmqN3uQ7FjRGTy")

      get public_band_path(band.slug)

      expect(response.body).to include(public_album_path(band.slug, album))
      expect(response.body).to include("Listen on Spotify")
    end

    it "does not show anything when the band has no published albums" do
      band = create(:band, :approved)
      create(:album, band: band, title: "Secret Album")

      get public_band_path(band.slug)

      expect(response.body).not_to include("Secret Album")
    end

    it "shows an album still in early access as locked, without linking to it, for a visitor without the required membership" do
      band = create(:band, :approved)
      album = create(:album, :published, band: band, title: "Early Album", early_access_level: :supporter, early_access_until: 1.day.from_now)

      get public_band_path(band.slug)

      # The title is shown deliberately (docs/band-admin.md §37 — don't
      # silently hide that the content exists), but the album page itself
      # stays out of reach.
      expect(response.body).to include("Early Album")
      expect(response.body).to include("Supporter early access")
      expect(response.body).not_to include(public_album_path(band.slug, album))
    end

    it "shows an album still in early access to a member who meets the required level" do
      band = create(:band, :approved)
      create(:album, :published, band: band, title: "Early Album", early_access_level: :supporter, early_access_until: 1.day.from_now)
      supporter = create(:user)
      create(:membership, band: band, user: supporter, level: :supporter)
      sign_in supporter

      get public_band_path(band.slug)

      expect(response.body).to include("Early Album")
    end

    it "shows an empty state when the band has no published albums, posts or events" do
      band = create(:band, :approved)

      get public_band_path(band.slug)

      expect(response.body).to include("No music, posts or shows published yet")
    end

    it "does not show the empty state when the band has a published album" do
      band = create(:band, :approved)
      create(:album, :published, band: band)

      get public_band_path(band.slug)

      expect(response.body).not_to include("No music, posts or shows published yet")
    end

    it "does not show the empty state when the band has a published post" do
      band = create(:band, :approved)
      create(:post, :published, band: band)

      get public_band_path(band.slug)

      expect(response.body).not_to include("No music, posts or shows published yet")
    end

    it "shows the follower count" do
      band = create(:band, :approved)
      create_list(:follow, 2, band: band)

      get public_band_path(band.slug)

      expect(response.body).to include("2 followers")
    end

    it "does not show a follow button to an anonymous visitor" do
      band = create(:band, :approved)

      get public_band_path(band.slug)

      expect(response.body).not_to include(">Follow<")
    end

    it "shows a Follow button to an authenticated user who does not follow the band" do
      user = create(:user)
      band = create(:band, :approved)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include(">Follow<")
      expect(response.body).not_to include(">Following<")
    end

    it "shows a Following button to a user who already follows the band" do
      user = create(:user)
      band = create(:band, :approved)
      create(:follow, user: user, band: band)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include(">Following<")
    end

    it "shows a published public post to an anonymous visitor" do
      band = create(:band, :approved)
      create(:post, :published, band: band, title: "Public News")

      get public_band_path(band.slug)

      expect(response.body).to include("Public News")
    end

    it "labels a composition journal entry visible to the viewer" do
      band = create(:band, :approved)
      create(:post, :published, :composition_journal, band: band, title: "How this song was born")
      user = create(:user)
      create(:membership, band: band, user: user, level: :supporter)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include("Composition Journal")
      expect(response.body).to include("How this song was born")
    end

    it "does not label a locked composition journal entry the viewer cannot see" do
      band = create(:band, :approved)
      create(:post, :published, :composition_journal, band: band, title: "How this song was born")
      user = create(:user)
      create(:membership, band: band, user: user, level: :fan)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).not_to include("Composition Journal")
    end

    it "does not label a regular announcement post" do
      band = create(:band, :approved)
      create(:post, :published, band: band, title: "Regular update")

      get public_band_path(band.slug)

      expect(response.body).not_to include("Composition Journal")
    end

    it "shows a published post's attached image" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band, title: "Public News")
      post_record.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/band_photo.png")),
        filename: "band_photo.png",
        content_type: "image/png"
      )

      get public_band_path(band.slug)

      expect(response.body).to include(rails_blob_path(post_record.image, only_path: true))
    end

    it "does not show an image element for a post without one" do
      band = create(:band, :approved)
      create(:post, :published, band: band, title: "Public News")

      get public_band_path(band.slug)

      expect(response.body).not_to include("rails/active_storage/blobs")
    end

    it "does not show a draft post" do
      band = create(:band, :approved)
      create(:post, band: band, title: "Draft News")

      get public_band_path(band.slug)

      expect(response.body).not_to include("Draft News")
    end

    it "locks a post still in early access for a visitor without the required level, showing its title but not its body" do
      band = create(:band, :approved)
      create(:post, :published, band: band, visibility: :public, title: "Early Post", body: "Secret body text", early_access_level: :supporter, early_access_until: 1.day.from_now)

      get public_band_path(band.slug)

      expect(response.body).to include("Early Post")
      expect(response.body).to include("Available to Supporters and above")
      expect(response.body).not_to include("Secret body text")
    end

    it "shows a post still in early access to a member who meets the required level" do
      band = create(:band, :approved)
      create(:post, :published, band: band, visibility: :public, title: "Early Post", body: "Unlocked body text", early_access_level: :supporter, early_access_until: 1.day.from_now)
      supporter = create(:user)
      create(:membership, band: band, user: supporter, level: :supporter)
      sign_in supporter

      get public_band_path(band.slug)

      expect(response.body).to include("Unlocked body text")
    end

    it "locks a followers-only post for an anonymous visitor, showing its title but not its body" do
      band = create(:band, :approved)
      create(:post, :published, :followers_only, band: band, title: "Followers News", body: "Secret body text")

      get public_band_path(band.slug)

      expect(response.body).to include("Followers News")
      expect(response.body).to include("Available to followers")
      expect(response.body).not_to include("Secret body text")
    end

    it "locks a followers-only post for an authenticated non-follower" do
      user = create(:user)
      band = create(:band, :approved)
      create(:post, :published, :followers_only, band: band, title: "Followers News", body: "Secret body text")
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include("Followers News")
      expect(response.body).to include("Follow this band to unlock")
      expect(response.body).not_to include("Secret body text")
    end

    it "shows a followers-only post to an authenticated follower" do
      user = create(:user)
      band = create(:band, :approved)
      create(:post, :published, :followers_only, band: band, title: "Followers News")
      create(:follow, user: user, band: band)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include("Followers News")
    end

    it "locks a fan-only post for a mere follower without a membership, prompting an upgrade" do
      user = create(:user)
      band = create(:band, :approved)
      create(:post, :published, :fan_only, band: band, title: "Fan News", body: "Secret body text")
      create(:follow, user: user, band: band)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include("Fan News")
      expect(response.body).to include("Upgrade to Fan")
      expect(response.body).not_to include("Secret body text")
    end

    it "shows a fan-only post to a user with an active Fan membership" do
      user = create(:user)
      band = create(:band, :approved)
      create(:post, :published, :fan_only, band: band, title: "Fan News")
      create(:membership, band: band, user: user, level: :fan)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include("Fan News")
    end

    it "shows a supporter-only post to a Core Member (higher levels see lower-level content)" do
      user = create(:user)
      band = create(:band, :approved)
      create(:post, :published, :supporter_only, band: band, title: "Supporter News")
      create(:membership, band: band, user: user, level: :core_member)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include("Supporter News")
    end

    it "locks a core-member-only post for a Fan, prompting an upgrade" do
      user = create(:user)
      band = create(:band, :approved)
      create(:post, :published, :core_member_only, band: band, title: "Core News", body: "Secret body text")
      create(:membership, band: band, user: user, level: :fan)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include("Core News")
      expect(response.body).to include("Upgrade to Core member")
      expect(response.body).not_to include("Secret body text")
    end

    it "locks a level-gated post when the membership is paused" do
      user = create(:user)
      band = create(:band, :approved)
      create(:post, :published, :fan_only, band: band, title: "Fan News", body: "Secret body text")
      create(:membership, band: band, user: user, level: :fan, status: :paused)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include("Fan News")
      expect(response.body).not_to include("Secret body text")
    end

    it "shows a published upcoming event to an anonymous visitor" do
      band = create(:band, :approved)
      create(:event, :published, band: band, title: "Album release show")

      get public_band_path(band.slug)

      expect(response.body).to include("Album release show")
    end

    it "shows the event's ticket link" do
      band = create(:band, :approved)
      create(:event, :published, band: band, ticket_url: "https://sympla.com.br/show")

      get public_band_path(band.slug)

      expect(response.body).to include("https://sympla.com.br/show")
    end

    it "does not show a draft event" do
      band = create(:band, :approved)
      create(:event, band: band, title: "Secret Show")

      get public_band_path(band.slug)

      expect(response.body).not_to include("Secret Show")
    end

    it "does not show a published event that already happened" do
      band = create(:band, :approved)
      create(:event, :published, :past, band: band, title: "Old Show")

      get public_band_path(band.slug)

      expect(response.body).not_to include("Old Show")
    end

    it "shows a published core session's details and RSVP button to a Core Member" do
      band = create(:band, :approved)
      session = create(:core_session, :published, band: band, title: "Private Listening Session", capacity: 20)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include("Private Listening Session")
      expect(response.body).to include(core_session_rsvp_path(band.slug, session))
    end

    it "locks a core session for a Supporter, showing its title but not its details" do
      band = create(:band, :approved)
      create(:core_session, :published, band: band, title: "Private Listening Session", description: "Secret details")
      user = create(:user)
      create(:membership, :supporter, band: band, user: user)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include("Private Listening Session")
      expect(response.body).to include("Available to Core members and above.")
      expect(response.body).not_to include("Secret details")
    end

    it "does not show a draft core session" do
      band = create(:band, :approved)
      create(:core_session, band: band, title: "Secret Session")

      get public_band_path(band.slug)

      expect(response.body).not_to include("Secret Session")
    end

    it "shows a cancel option instead of RSVP once the Core Member has RSVPed" do
      band = create(:band, :approved)
      session = create(:core_session, :published, band: band)
      user = create(:user)
      create(:membership, :core_member, band: band, user: user)
      create(:core_session_rsvp, core_session: session, user: user)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include("You're on the list")
      expect(response.body).to include(cancel_core_session_rsvp_path(band.slug, session))
    end

    it "does not show the empty state when the band has a published event" do
      band = create(:band, :approved)
      create(:event, :published, band: band)

      get public_band_path(band.slug)

      expect(response.body).not_to include("No music, posts or shows published yet")
    end

    it "shows a published poll's question to an anonymous visitor" do
      band = create(:band, :approved)
      create(:poll, :published, band: band, question: "Which song should we play live?")

      get public_band_path(band.slug)

      expect(response.body).to include("Which song should we play live?")
    end

    it "does not show a draft poll" do
      band = create(:band, :approved)
      create(:poll, band: band, question: "Draft Poll Question")

      get public_band_path(band.slug)

      expect(response.body).not_to include("Draft Poll Question")
    end

    it "locks a fan-only poll for an anonymous visitor, showing its question but not its options" do
      band = create(:band, :approved)
      poll = create(:poll, :published, :fan_only, band: band, question: "Fan Poll Question")
      poll.poll_options.first.update!(label: "Secret Option Label")

      get public_band_path(band.slug)

      expect(response.body).to include("Fan Poll Question")
      expect(response.body).to include("Available to Fans and above")
      expect(response.body).not_to include("Secret Option Label")
    end

    it "shows a fan-only poll to a user with an active Fan membership" do
      band = create(:band, :approved)
      poll = create(:poll, :published, :fan_only, band: band, question: "Fan Poll Question")
      user = create(:user)
      create(:membership, band: band, user: user, level: :fan)
      sign_in user

      get public_band_path(band.slug)

      expect(response.body).to include("Fan Poll Question")
      poll.poll_options.each { |option| expect(response.body).to include(option.label) }
    end
  end

  describe "GET /:slug/subscriptions" do
    it "shows the three membership levels to a signed-in user" do
      band = create(:band, :approved, name: "The Testers")
      user = create(:user)
      sign_in user

      get public_band_subscriptions_path(band.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Join as Fan")
      expect(response.body).to include("Join as Supporter")
      expect(response.body).to include("Join as Core Member")
    end

    it "shows the user's current membership level and a cancel option for that plan" do
      band = create(:band, :approved)
      user = create(:user)
      create(:membership, band: band, user: user, level: :supporter)
      sign_in user

      get public_band_subscriptions_path(band.slug)

      expect(response.body).to include("Current plan")
      expect(response.body).to include("Cancel plan")
      expect(response.body).to include("Join as Fan")
    end

    it "prompts an anonymous visitor to sign in instead of showing plan buttons" do
      band = create(:band, :approved)

      get public_band_subscriptions_path(band.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sign in")
      expect(response.body).not_to include("Join as Fan")
    end

    it "returns 404 for a band that is not approved" do
      band = create(:band, name: "Pending Band")

      get public_band_subscriptions_path(band.slug)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for a nonexistent slug" do
      get public_band_subscriptions_path("no-such-band")

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "route precedence" do
    it "does not shadow the management area routes" do
      get bands_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not shadow the profile route" do
      get profile_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not shadow the root route" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("SceneCore")
    end
  end
end
