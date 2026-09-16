require "rails_helper"

RSpec.describe "Comments", type: :request do
  describe "POST /:slug/posts/:post_id/comments" do
    it "lets a signed-in user comment on a public post" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band, visibility: :public)
      user = create(:user)
      sign_in user

      post post_comments_path(band.slug, post_record), params: { comment: { body: "Loved this!" } }

      expect(response).to redirect_to(public_band_path(band.slug, anchor: "post-#{post_record.id}"))
      comment = Comment.find_by(post: post_record, user: user)
      expect(comment).to be_present
      expect(comment.body).to eq("Loved this!")
    end

    it "requires authentication" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band, visibility: :public)

      post post_comments_path(band.slug, post_record), params: { comment: { body: "Loved this!" } }

      expect(response).to redirect_to(new_user_session_path)
      expect(Comment.find_by(post: post_record)).to be_nil
    end

    it "does not let a non-follower comment on a followers-only post" do
      band = create(:band, :approved)
      post_record = create(:post, :published, :followers_only, band: band)
      user = create(:user)
      sign_in user

      post post_comments_path(band.slug, post_record), params: { comment: { body: "Loved this!" } }

      expect(response).to redirect_to(root_path)
      expect(Comment.find_by(post: post_record)).to be_nil
    end

    it "lets a follower comment on a followers-only post" do
      band = create(:band, :approved)
      post_record = create(:post, :published, :followers_only, band: band)
      user = create(:user)
      create(:follow, band: band, user: user)
      sign_in user

      post post_comments_path(band.slug, post_record), params: { comment: { body: "Loved this!" } }

      expect(Comment.find_by(post: post_record, user: user)).to be_present
    end

    it "does not let a fan comment on a supporter-only post" do
      band = create(:band, :approved)
      post_record = create(:post, :published, :supporter_only, band: band)
      user = create(:user)
      create(:membership, band: band, user: user, level: :fan)
      sign_in user

      post post_comments_path(band.slug, post_record), params: { comment: { body: "Loved this!" } }

      expect(response).to redirect_to(root_path)
      expect(Comment.find_by(post: post_record)).to be_nil
    end

    it "rejects a blank comment" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band, visibility: :public)
      user = create(:user)
      sign_in user

      post post_comments_path(band.slug, post_record), params: { comment: { body: "" } }

      expect(Comment.find_by(post: post_record)).to be_nil
    end

    it "returns 404 for a draft post" do
      band = create(:band, :approved)
      post_record = create(:post, band: band, visibility: :public)
      user = create(:user)
      sign_in user

      post post_comments_path(band.slug, post_record), params: { comment: { body: "Loved this!" } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /:slug/posts/:post_id/comments/:id" do
    it "lets the comment's author delete it" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band, visibility: :public)
      author = create(:user)
      comment = create(:comment, post: post_record, user: author)
      sign_in author

      delete post_comment_path(band.slug, post_record, comment)

      expect(response).to redirect_to(public_band_path(band.slug, anchor: "post-#{post_record.id}"))
      expect(Comment.exists?(comment.id)).to be false
    end

    it "does not log an audit entry when the author deletes their own comment" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band, visibility: :public)
      author = create(:user)
      comment = create(:comment, post: post_record, user: author)
      sign_in author

      expect {
        delete post_comment_path(band.slug, post_record, comment)
      }.not_to change(AdminActionLog, :count)
    end

    it "lets a member of the band delete a comment on the band's post" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band, visibility: :public)
      comment = create(:comment, post: post_record)
      band_member = create(:user)
      create(:band_membership, band: band, user: band_member)
      sign_in band_member

      delete post_comment_path(band.slug, post_record, comment)

      expect(Comment.exists?(comment.id)).to be false
    end

    it "does not log an audit entry when the band deletes a comment on its own post" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band, visibility: :public)
      comment = create(:comment, post: post_record)
      band_member = create(:user)
      create(:band_membership, band: band, user: band_member)
      sign_in band_member

      expect {
        delete post_comment_path(band.slug, post_record, comment)
      }.not_to change(AdminActionLog, :count)
    end

    it "lets a platform administrator delete any comment" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band, visibility: :public)
      comment = create(:comment, post: post_record)
      admin = create(:user, :platform_admin)
      sign_in admin

      delete post_comment_path(band.slug, post_record, comment)

      expect(Comment.exists?(comment.id)).to be false
    end

    it "logs an audit entry when a platform admin deletes another band's comment" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band, visibility: :public)
      comment = create(:comment, post: post_record)
      admin = create(:user, :platform_admin)
      sign_in admin

      delete post_comment_path(band.slug, post_record, comment)

      log = AdminActionLog.last
      expect(log.action).to eq("moderate_delete_comment")
      expect(log.actor).to eq(admin)
    end

    it "returns 404 when an unrelated fan tries to delete someone else's comment" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band, visibility: :public)
      comment = create(:comment, post: post_record)
      outsider = create(:user)
      sign_in outsider

      delete post_comment_path(band.slug, post_record, comment)

      expect(response).to redirect_to(root_path)
      expect(Comment.exists?(comment.id)).to be true
    end

    it "requires authentication" do
      band = create(:band, :approved)
      post_record = create(:post, :published, band: band, visibility: :public)
      comment = create(:comment, post: post_record)

      delete post_comment_path(band.slug, post_record, comment)

      expect(response).to redirect_to(new_user_session_path)
      expect(Comment.exists?(comment.id)).to be true
    end
  end
end
