require "rails_helper"

RSpec.describe PlatformSetting, type: :model do
  describe ".current" do
    it "creates the singleton row if none exists" do
      expect { PlatformSetting.current }.to change(PlatformSetting, :count).by(1)
    end

    it "returns the same row on subsequent calls" do
      first = PlatformSetting.current
      second = PlatformSetting.current

      expect(second.id).to eq(first.id)
    end

    it "defaults band_signups_enabled to true" do
      expect(PlatformSetting.current.band_signups_enabled).to be true
    end

    it "defaults platform_fee_percentage to 0" do
      expect(PlatformSetting.current.platform_fee_percentage).to eq(0)
    end
  end

  it "rejects a platform fee below 0" do
    expect(build(:platform_setting, platform_fee_percentage: -1)).not_to be_valid
  end

  it "rejects a platform fee above 100" do
    expect(build(:platform_setting, platform_fee_percentage: 101)).not_to be_valid
  end

  it "rejects a malformed support email" do
    expect(build(:platform_setting, support_email: "not-an-email")).not_to be_valid
  end

  it "rejects a malformed notification sender email" do
    expect(build(:platform_setting, notification_sender_email: "not-an-email")).not_to be_valid
  end

  it "allows blank support and notification emails" do
    expect(build(:platform_setting, support_email: nil, notification_sender_email: nil)).to be_valid
  end
end
