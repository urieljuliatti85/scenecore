require "rails_helper"

RSpec.describe "Posts", type: :request do
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
  end
end
