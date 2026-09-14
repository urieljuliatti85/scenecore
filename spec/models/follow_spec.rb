require "rails_helper"

RSpec.describe Follow, type: :model do
  it "is valid with valid attributes" do
    expect(build(:follow)).to be_valid
  end

  it "requires a user" do
    follow = build(:follow, user: nil)

    expect(follow).not_to be_valid
  end

  it "requires a band" do
    follow = build(:follow, band: nil)

    expect(follow).not_to be_valid
  end

  it "prevents a user from following the same band twice (model validation)" do
    band = create(:band)
    user = create(:user)
    create(:follow, user: user, band: band)

    duplicate = build(:follow, user: user, band: band)

    expect(duplicate).not_to be_valid
  end

  it "prevents a duplicate follow at the database level" do
    band = create(:band)
    user = create(:user)
    create(:follow, user: user, band: band)

    duplicate = build(:follow, user: user, band: band)

    expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "allows the same user to follow different bands" do
    user = create(:user)
    band_a = create(:band)
    band_b = create(:band)
    create(:follow, user: user, band: band_a)

    expect(build(:follow, user: user, band: band_b)).to be_valid
  end

  it "allows different users to follow the same band" do
    band = create(:band)
    user_a = create(:user)
    user_b = create(:user)
    create(:follow, user: user_a, band: band)

    expect(build(:follow, user: user_b, band: band)).to be_valid
  end
end
