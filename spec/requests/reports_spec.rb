require "rails_helper"

RSpec.describe "Reports", type: :request do
  describe "POST /:slug/posts/:post_id/report" do
    it "lets a signed-in user report a visible post" do
      band = create(:band, :approved)
      post = create(:post, :published, band: band, visibility: :public)
      user = create(:user)
      sign_in user

      expect {
        post report_post_path(band.slug, post), params: { report: { reason: "This is spam" } }
      }.to change(Report, :count).by(1)

      report = Report.last
      expect(report.reportable).to eq(post)
      expect(report.reporter).to eq(user)
      expect(response).to redirect_to(public_band_path(band.slug, anchor: "post-#{post.id}"))
    end

    it "requires authentication" do
      band = create(:band, :approved)
      post = create(:post, :published, band: band, visibility: :public)

      post report_post_path(band.slug, post), params: { report: { reason: "This is spam" } }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "does not let a user report a post they can't see" do
      band = create(:band, :approved)
      post = create(:post, :published, :supporter_only, band: band)
      user = create(:user)
      sign_in user

      expect {
        post report_post_path(band.slug, post), params: { report: { reason: "This is spam" } }
      }.not_to change(Report, :count)

      expect(response).to redirect_to(root_path)
    end

    it "returns 404 for a draft post" do
      band = create(:band, :approved)
      post = create(:post, band: band, visibility: :public)
      user = create(:user)
      sign_in user

      post report_post_path(band.slug, post), params: { report: { reason: "This is spam" } }

      expect(response).to have_http_status(:not_found)
    end

    it "rejects a blank reason" do
      band = create(:band, :approved)
      post = create(:post, :published, band: band, visibility: :public)
      user = create(:user)
      sign_in user

      expect {
        post report_post_path(band.slug, post), params: { report: { reason: "" } }
      }.not_to change(Report, :count)
    end
  end

  describe "POST /:slug/posts/:post_id/comments/:comment_id/report" do
    it "lets a signed-in user report a comment" do
      band = create(:band, :approved)
      post = create(:post, :published, band: band, visibility: :public)
      comment = create(:comment, post: post)
      user = create(:user)
      sign_in user

      expect {
        post report_comment_path(band.slug, post, comment), params: { report: { reason: "Offensive language" } }
      }.to change(Report, :count).by(1)

      expect(Report.last.reportable).to eq(comment)
    end

    it "does not let a user report a comment on a post they can't see" do
      band = create(:band, :approved)
      post = create(:post, :published, :supporter_only, band: band)
      comment = create(:comment, post: post)
      user = create(:user)
      sign_in user

      expect {
        post report_comment_path(band.slug, post, comment), params: { report: { reason: "Offensive language" } }
      }.not_to change(Report, :count)
    end
  end
end
