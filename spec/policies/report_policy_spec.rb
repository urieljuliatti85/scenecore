require "rails_helper"

RSpec.describe ReportPolicy do
  describe "#create?" do
    context "when reporting a post" do
      it "is true when the user can see the post" do
        band = create(:band)
        post = create(:post, :published, band: band, visibility: :public)
        user = create(:user)
        report = build(:report, reportable: post, reporter: user)

        expect(described_class.new(user, report).create?).to be true
      end

      it "is false when the user cannot see the post" do
        band = create(:band)
        post = create(:post, :published, :supporter_only, band: band)
        user = create(:user)
        report = build(:report, reportable: post, reporter: user)

        expect(described_class.new(user, report).create?).to be false
      end

      it "is false for an anonymous visitor" do
        post = create(:post, :published, visibility: :public)
        report = build(:report, reportable: post)

        expect(described_class.new(nil, report).create?).to be false
      end
    end

    context "when reporting a comment" do
      it "is true when the user can see the comment's post" do
        band = create(:band)
        post = create(:post, :published, band: band, visibility: :public)
        comment = create(:comment, post: post)
        user = create(:user)
        report = build(:report, reportable: comment, reporter: user)

        expect(described_class.new(user, report).create?).to be true
      end

      it "is false when the user cannot see the comment's post" do
        band = create(:band)
        post = create(:post, :published, :supporter_only, band: band)
        comment = create(:comment, post: post)
        user = create(:user)
        report = build(:report, reportable: comment, reporter: user)

        expect(described_class.new(user, report).create?).to be false
      end
    end
  end
end
