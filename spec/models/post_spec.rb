require "rails_helper"

RSpec.describe Post, type: :model do
  it "is valid with valid attributes" do
    expect(build(:post)).to be_valid
  end

  it "requires a title" do
    post = build(:post, title: nil)

    expect(post).not_to be_valid
  end

  it "requires a band" do
    post = build(:post, band: nil)

    expect(post).not_to be_valid
  end

  it "defaults status to draft" do
    expect(create(:post).status).to eq("draft")
  end

  it "restricts status to draft or published" do
    post = build(:post)
    post.status = "archived"

    expect(post).not_to be_valid
  end

  it "defaults visibility to public" do
    expect(create(:post).visibility).to eq("public")
  end

  it "restricts visibility to public, followers, or subscribers" do
    post = build(:post)
    post.visibility = "everyone"

    expect(post).not_to be_valid
  end

  it "belongs to a band" do
    band = create(:band)
    post = create(:post, band: band)

    expect(post.band).to eq(band)
  end
end
