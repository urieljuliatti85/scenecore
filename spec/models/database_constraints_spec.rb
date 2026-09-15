require "rails_helper"

# These enum-backed columns are plain strings in Postgres. The models
# validate them, but `update_all`/`update_column` and anything writing
# outside Active Record bypass that — AlbumsController and
# Admin::AlbumsController both use `update_all` on `status` today. These
# specs pin the database-level guarantee, not the model validation.
RSpec.describe "Database check constraints" do
  def expect_rejected(scope, attributes)
    expect { scope.update_all(attributes) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  describe "bands.status" do
    it "rejects a value outside the enum" do
      band = create(:band)

      expect_rejected(Band.where(id: band.id), status: "not_a_status")
    end

    it "accepts every value the enum defines" do
      band = create(:band)

      Band.statuses.each_value do |status|
        expect { Band.where(id: band.id).update_all(status: status) }.not_to raise_error
      end
    end
  end

  describe "band_memberships.role" do
    it "rejects a value outside the enum" do
      membership = create(:band_membership)

      expect_rejected(BandMembership.where(id: membership.id), role: "superuser")
    end
  end

  describe "albums.status" do
    it "rejects a value outside the enum" do
      album = create(:album)

      expect_rejected(Album.where(id: album.id), status: "archived")
    end
  end

  describe "tracks.status" do
    it "rejects a value outside the enum" do
      track = create(:track)

      expect_rejected(Track.where(id: track.id), status: "archived")
    end
  end

  describe "posts.status" do
    it "rejects a value outside the enum" do
      post = create(:post)

      expect_rejected(Post.where(id: post.id), status: "archived")
    end
  end

  describe "posts.visibility" do
    it "rejects a value outside the enum" do
      post = create(:post)

      expect_rejected(Post.where(id: post.id), visibility: "everyone")
    end

    it "accepts every value the enum defines" do
      post = create(:post)

      Post.visibilities.each_value do |visibility|
        expect { Post.where(id: post.id).update_all(visibility: visibility) }.not_to raise_error
      end
    end
  end
end
