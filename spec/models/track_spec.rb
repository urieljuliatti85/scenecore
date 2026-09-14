require "rails_helper"

RSpec.describe Track, type: :model do
  it "is valid with valid attributes" do
    expect(build(:track)).to be_valid
  end

  it "requires a title" do
    track = build(:track, title: nil)

    expect(track).not_to be_valid
  end

  it "requires a band" do
    track = build(:track, band: nil)

    expect(track).not_to be_valid
  end

  it "defaults status to draft" do
    expect(create(:track).status).to eq("draft")
  end

  it "restricts status to draft or published" do
    track = build(:track)
    track.status = "archived"

    expect(track).not_to be_valid
  end

  it "belongs to a band" do
    band = create(:band)
    track = create(:track, band: band)

    expect(track.band).to eq(band)
  end
end
