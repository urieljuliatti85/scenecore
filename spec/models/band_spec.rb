require "rails_helper"

RSpec.describe Band, type: :model do
  it "is valid with valid attributes" do
    expect(build(:band)).to be_valid
  end

  it "requires a name" do
    band = build(:band, name: nil)

    expect(band).not_to be_valid
  end

  it "generates a slug from the name on create" do
    band = create(:band, name: "The Testers")

    expect(band.slug).to eq("the-testers")
  end

  it "generates a unique slug when names collide" do
    create(:band, name: "The Testers")
    other = create(:band, name: "The Testers")

    expect(other.slug).to eq("the-testers-2")
  end

  it "rejects a duplicate slug at the database level even if validation is bypassed" do
    create(:band, name: "The Testers")
    duplicate = build(:band, name: "Other name")
    duplicate.slug = "the-testers"

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "defaults status to pending" do
    expect(create(:band).status).to eq("pending")
  end

  it "restricts status to pending, approved, or rejected" do
    band = build(:band)
    band.status = "suspended"

    expect(band).not_to be_valid
  end

  it "has many members through band memberships" do
    band = create(:band)
    user = create(:user)
    create(:band_membership, band: band, user: user)

    expect(band.members).to contain_exactly(user)
  end
end
