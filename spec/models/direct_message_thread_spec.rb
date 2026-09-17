require "rails_helper"

RSpec.describe DirectMessageThread, type: :model do
  it "is valid with valid attributes" do
    expect(build(:direct_message_thread)).to be_valid
  end

  it "defaults status to open" do
    expect(create(:direct_message_thread).status).to eq("open")
  end

  it "restricts status to open, archived, or blocked" do
    thread = build(:direct_message_thread)
    thread.status = "deleted"

    expect(thread).not_to be_valid
  end

  it "only allows one thread per user per band" do
    band = create(:band)
    user = create(:user)
    create(:direct_message_thread, band: band, user: user)

    expect(build(:direct_message_thread, band: band, user: user)).not_to be_valid
  end

  it "allows the same user to have threads with different bands" do
    user = create(:user)
    create(:direct_message_thread, band: create(:band), user: user)

    expect(build(:direct_message_thread, band: create(:band), user: user)).to be_valid
  end

  describe "#messageable_by_member?" do
    it "is true when open" do
      expect(build(:direct_message_thread, status: :open).messageable_by_member?).to be true
    end

    it "is true when archived" do
      expect(build(:direct_message_thread, status: :archived).messageable_by_member?).to be true
    end

    it "is false when blocked" do
      expect(build(:direct_message_thread, status: :blocked).messageable_by_member?).to be false
    end
  end
end
