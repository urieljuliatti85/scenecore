require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with valid attributes" do
    expect(build(:user)).to be_valid
  end

  it "requires a name" do
    user = build(:user, name: nil)

    expect(user).not_to be_valid
    expect(user.errors[:name]).to be_present
  end

  it "requires a unique email" do
    create(:user, email: "taken@example.com")
    user = build(:user, email: "taken@example.com")

    expect(user).not_to be_valid
    expect(user.errors[:email]).to be_present
  end

  it "rejects a duplicate email at the database level even if validation is bypassed" do
    create(:user, email: "taken@example.com")
    user = build(:user, email: "taken@example.com")

    expect { user.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "defaults platform_admin to false" do
    expect(create(:user).platform_admin).to eq(false)
  end

  it "has many band memberships and bands through them" do
    user = create(:user)
    band = create(:band)
    create(:band_membership, user: user, band: band)

    expect(user.bands).to contain_exactly(band)
  end

  it "has many follows and followed bands through them" do
    user = create(:user)
    band = create(:band)
    create(:follow, user: user, band: band)

    expect(user.followed_bands).to contain_exactly(band)
  end

  it "destroys its follows when destroyed" do
    user = create(:user)
    create(:follow, user: user)

    expect { user.destroy }.to change(Follow, :count).by(-1)
  end

  describe "last platform admin protection" do
    it "prevents destroying the only platform admin" do
      admin = create(:user, :platform_admin)

      expect(admin.destroy).to be false
      expect(admin.errors[:base]).to include("cannot remove the last platform administrator")
      expect(User.exists?(admin.id)).to be true
    end

    it "allows destroying a platform admin when another one exists" do
      admin = create(:user, :platform_admin)
      create(:user, :platform_admin)

      expect(admin.destroy).to be_truthy
    end

    it "prevents demoting the only platform admin" do
      admin = create(:user, :platform_admin)

      expect(admin.update(platform_admin: false)).to be false
      expect(admin.errors[:base]).to include("cannot demote the last platform administrator")
      expect(admin.reload.platform_admin?).to be true
    end

    it "allows demoting a platform admin when another one exists" do
      admin = create(:user, :platform_admin)
      create(:user, :platform_admin)

      expect(admin.update(platform_admin: false)).to be true
    end

    it "allows destroying a non-admin user" do
      user = create(:user)

      expect(user.destroy).to be_truthy
    end
  end
end
