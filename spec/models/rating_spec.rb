require "rails_helper"

RSpec.describe Rating, type: :model do
  it "is valid with valid attributes" do
    expect(build(:rating)).to be_valid
  end

  it "requires a score between 1 and 5" do
    rating = build(:rating, score: 6)

    expect(rating).not_to be_valid
    expect(rating.errors[:score]).to be_present
  end

  it "rejects a score below 1" do
    rating = build(:rating, score: 0)

    expect(rating).not_to be_valid
  end

  it "prevents the same user from rating the same album twice" do
    album = create(:album)
    user = create(:user)
    create(:rating, album: album, user: user, score: 3)
    duplicate = build(:rating, album: album, user: user, score: 5)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to be_present
  end

  it "rejects a duplicate rating at the database level even if validation is bypassed" do
    album = create(:album)
    user = create(:user)
    create(:rating, album: album, user: user, score: 3)
    duplicate = build(:rating, album: album, user: user, score: 5)

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows the same user to rate different albums" do
    user = create(:user)
    album_a = create(:album)
    album_b = create(:album)
    create(:rating, album: album_a, user: user, score: 3)
    create(:rating, album: album_b, user: user, score: 5)

    expect(user.ratings.count).to eq(2)
  end

  describe "Album#average_rating and #ratings_count" do
    it "computes the average across all ratings" do
      album = create(:album)
      create(:rating, album: album, score: 3)
      create(:rating, album: album, score: 5)

      expect(album.average_rating).to eq(4.0)
      expect(album.ratings_count).to eq(2)
    end

    it "returns nil average and zero count when there are no ratings" do
      album = create(:album)

      expect(album.average_rating).to be_nil
      expect(album.ratings_count).to eq(0)
    end
  end
end
