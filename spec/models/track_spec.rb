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

  it "is valid without a spotify_url" do
    expect(build(:track, spotify_url: nil)).to be_valid
  end

  it "is valid with a Spotify track URL" do
    track = build(:track, spotify_url: "https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC")

    expect(track).to be_valid
  end

  it "is valid with a Spotify track URL that has a query string" do
    track = build(:track, spotify_url: "https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC?si=abc123")

    expect(track).to be_valid
  end

  it "is invalid with a non-Spotify URL" do
    track = build(:track, spotify_url: "https://example.com/song")

    expect(track).not_to be_valid
  end

  it "is invalid with a Spotify URL that is not a track link" do
    track = build(:track, spotify_url: "https://open.spotify.com/album/4uLU6hMCjMI75M1A2tKUQC")

    expect(track).not_to be_valid
  end
end
