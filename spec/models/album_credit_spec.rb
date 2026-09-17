require "rails_helper"

RSpec.describe AlbumCredit, type: :model do
  it "is valid when the user has an active Supporter membership with the album's band" do
    band = create(:band)
    album = create(:album, band: band)
    user = create(:user)
    create(:membership, :supporter, band: band, user: user)

    expect(build(:album_credit, album: album, user: user)).to be_valid
  end

  it "is valid when the user has an active Core Member membership with the album's band" do
    band = create(:band)
    album = create(:album, band: band)
    user = create(:user)
    create(:membership, :core_member, band: band, user: user)

    expect(build(:album_credit, album: album, user: user)).to be_valid
  end

  it "is invalid when the user only has a Fan membership with the album's band" do
    band = create(:band)
    album = create(:album, band: band)
    user = create(:user)
    create(:membership, band: band, user: user, level: :fan)

    expect(build(:album_credit, album: album, user: user)).not_to be_valid
  end

  it "is invalid when the user has no membership with the album's band" do
    band = create(:band)
    album = create(:album, band: band)
    user = create(:user)

    expect(build(:album_credit, album: album, user: user)).not_to be_valid
  end

  it "is invalid when the user's Supporter membership with the album's band is paused" do
    band = create(:band)
    album = create(:album, band: band)
    user = create(:user)
    create(:membership, :supporter, :paused, band: band, user: user)

    expect(build(:album_credit, album: album, user: user)).not_to be_valid
  end

  it "is invalid when the user's Supporter membership belongs to a different band" do
    band = create(:band)
    other_band = create(:band)
    album = create(:album, band: band)
    user = create(:user)
    create(:membership, :supporter, band: other_band, user: user)

    expect(build(:album_credit, album: album, user: user)).not_to be_valid
  end

  it "does not allow crediting the same user twice on the same album" do
    band = create(:band)
    album = create(:album, band: band)
    user = create(:user)
    create(:membership, :supporter, band: band, user: user)
    create(:album_credit, album: album, user: user)

    expect(build(:album_credit, album: album, user: user)).not_to be_valid
  end

  it "allows crediting the same user on a different album" do
    band = create(:band)
    album = create(:album, band: band)
    other_album = create(:album, band: band)
    user = create(:user)
    create(:membership, :supporter, band: band, user: user)
    create(:album_credit, album: album, user: user)

    expect(build(:album_credit, album: other_album, user: user)).to be_valid
  end
end
