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

  # Devise delivers inline, so without this an unreachable mail provider
  # turns "forgot my password" into a 500 the user can do nothing about.
  describe "notification delivery failures" do
    let(:user) { create(:user) }

    before do
      allow(Devise.mailer).to receive(:reset_password_instructions)
        .and_raise(Net::OpenTimeout, "execution expired")
    end

    it "does not raise when the mail provider is unreachable" do
      expect { user.send_reset_password_instructions }.not_to raise_error
    end

    it "still generates the reset token, so a retry can deliver it" do
      user.send_reset_password_instructions

      expect(user.reload.reset_password_token).to be_present
    end

    it "logs the failure rather than swallowing it silently" do
      allow(Rails.logger).to receive(:error)

      user.send_reset_password_instructions

      expect(Rails.logger).to have_received(:error).with(/delivery failed.*Net::OpenTimeout/)
    end
  end
end
