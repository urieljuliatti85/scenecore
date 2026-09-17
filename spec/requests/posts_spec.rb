require "rails_helper"

RSpec.describe "Posts", type: :request do
  describe "GET /bands/:band_id/posts/:id" do
    it "requires authentication" do
      post_record = create(:post)

      get band_post_path(post_record.band, post_record)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the post body to a band member" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      post_record = create(:post, band: band, title: "On tour", body: "We are playing in Recife")
      sign_in user

      get band_post_path(band, post_record)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("On tour")
      expect(response.body).to include("We are playing in Recife")
    end

    it "prevents a member of another band from viewing the post" do
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      post_record = create(:post)
      sign_in outsider

      get band_post_path(post_record.band, post_record)

      expect(response).to redirect_to(root_path)
    end

    it "does not expose a post belonging to a different band" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      other_post = create(:post)
      sign_in user

      get band_post_path(band, other_post)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /bands/:band_id/posts" do
    it "creates a post for a band member" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      expect {
        post band_posts_path(band), params: { post: { title: "News", body: "Something happened.", visibility: "public" } }
      }.to change(Post, :count).by(1)

      expect(Post.last.band).to eq(band)
      expect(response).to redirect_to(band_path(band))
    end

    it "does not create a post without a title" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      expect {
        post band_posts_path(band), params: { post: { title: "", body: "Something." } }
      }.not_to change(Post, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "creates a composition journal entry" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      post band_posts_path(band), params: { post: { title: "How this song was born", body: "Notes.", visibility: "supporter", post_type: "composition_journal" } }

      expect(Post.last.post_type).to eq("composition_journal")
    end

    it "defaults post_type to announcement when not specified" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      post band_posts_path(band), params: { post: { title: "News", body: "Something happened.", visibility: "public" } }

      expect(Post.last.post_type).to eq("announcement")
    end

    it "creates a post with an attached image" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      image = fixture_file_upload("spec/fixtures/files/band_photo.png", "image/png")

      post band_posts_path(band), params: { post: { title: "News", body: "Something happened.", visibility: "public", image: image } }

      expect(Post.last.image).to be_attached
    end

    it "rejects an attached file that isn't a valid image" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      image = fixture_file_upload("spec/fixtures/files/invalid_photo.txt", "text/plain")

      expect {
        post band_posts_path(band), params: { post: { title: "News", visibility: "public", image: image } }
      }.not_to change(Post, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "creates a post with attached composition files" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      attachment = fixture_file_upload("spec/fixtures/files/demo.pdf", "application/pdf")

      post band_posts_path(band), params: { post: { title: "Composition Journal", body: "How this song was made.", visibility: "supporter", attachments: [ attachment ] } }

      expect(Post.last.attachments).to be_attached
    end

    it "rejects a composition file with a disallowed content type" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      attachment = fixture_file_upload("spec/fixtures/files/invalid_photo.txt", "text/plain")

      expect {
        post band_posts_path(band), params: { post: { title: "Composition Journal", visibility: "supporter", attachments: [ attachment ] } }
      }.not_to change(Post, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires authentication" do
      band = create(:band)

      expect {
        post band_posts_path(band), params: { post: { title: "News" } }
      }.not_to change(Post, :count)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "prevents a member of another band from creating a post" do
      band = create(:band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      expect {
        post band_posts_path(band), params: { post: { title: "News" } }
      }.not_to change(Post, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /bands/:band_id/posts/:id" do
    it "allows a band member to update a post" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      post_record = create(:post, band: band, title: "Old title")
      sign_in user

      patch band_post_path(band, post_record), params: { post: { title: "New title" } }

      expect(post_record.reload.title).to eq("New title")
      expect(response).to redirect_to(band_path(band))
    end

    it "prevents a member of another band from updating the post" do
      band = create(:band)
      post_record = create(:post, band: band, title: "Old title")
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      patch band_post_path(band, post_record), params: { post: { title: "Hijacked" } }

      expect(post_record.reload.title).to eq("Old title")
      expect(response).to redirect_to(root_path)
    end

    it "lets a band member configure early access" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      post_record = create(:post, band: band)
      sign_in user

      patch band_post_path(band, post_record), params: { post: { early_access_level: "supporter", early_access_until: 1.day.from_now } }

      expect(response).to redirect_to(band_path(band))
      post_record.reload
      expect(post_record.early_access_level).to eq("supporter")
      expect(post_record.early_access_until).to be_present
    end
  end

  describe "DELETE /bands/:band_id/posts/:id" do
    it "allows a band member to delete a post" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      post_record = create(:post, band: band)
      sign_in user

      expect {
        delete band_post_path(band, post_record)
      }.to change(Post, :count).by(-1)

      expect(response).to redirect_to(band_path(band))
    end

    it "prevents a member of another band from deleting the post" do
      band = create(:band)
      post_record = create(:post, band: band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      expect {
        delete band_post_path(band, post_record)
      }.not_to change(Post, :count)

      expect(response).to redirect_to(root_path)
    end

    it "does not log an audit entry when the band deletes its own post" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      post_record = create(:post, band: band)
      sign_in user

      expect {
        delete band_post_path(band, post_record)
      }.not_to change(AdminActionLog, :count)
    end

    it "logs an audit entry when a platform admin deletes another band's post" do
      band = create(:band)
      post_record = create(:post, band: band)
      admin = create(:user, :platform_admin)
      sign_in admin

      delete band_post_path(band, post_record)

      log = AdminActionLog.last
      expect(log.action).to eq("moderate_delete_post")
      expect(log.actor).to eq(admin)
    end
  end

  describe "PATCH /bands/:band_id/posts/:id/publish" do
    it "publishes the post" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      post_record = create(:post, band: band)
      sign_in user

      patch publish_band_post_path(band, post_record)

      expect(post_record.reload.status).to eq("published")
    end

    it "prevents a member of another band from publishing the post" do
      band = create(:band)
      post_record = create(:post, band: band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      patch publish_band_post_path(band, post_record)

      expect(post_record.reload.status).to eq("draft")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /bands/:band_id/posts/:id/unpublish" do
    it "unpublishes the post" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      post_record = create(:post, :published, band: band)
      sign_in user

      patch unpublish_band_post_path(band, post_record)

      expect(post_record.reload.status).to eq("draft")
    end

    it "does not log an audit entry when the band unpublishes its own post" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      post_record = create(:post, :published, band: band)
      sign_in user

      expect {
        patch unpublish_band_post_path(band, post_record)
      }.not_to change(AdminActionLog, :count)
    end

    it "logs an audit entry when a platform admin unpublishes another band's post" do
      band = create(:band)
      post_record = create(:post, :published, band: band)
      admin = create(:user, :platform_admin)
      sign_in admin

      patch unpublish_band_post_path(band, post_record)

      log = AdminActionLog.last
      expect(log.action).to eq("moderate_unpublish_post")
      expect(log.actor).to eq(admin)
      expect(log.subject).to eq(post_record)
    end
  end
end
