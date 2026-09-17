require "rails_helper"

RSpec.describe DirectMessage, type: :model do
  it "is valid with valid attributes" do
    expect(build(:direct_message)).to be_valid
  end

  it "requires a body" do
    expect(build(:direct_message, body: nil)).not_to be_valid
  end

  it "rejects a blank body" do
    expect(build(:direct_message, body: "")).not_to be_valid
  end

  it "rejects a body over 2000 characters" do
    expect(build(:direct_message, body: "a" * 2001)).not_to be_valid
  end

  it "accepts a body at exactly 2000 characters" do
    expect(build(:direct_message, body: "a" * 2000)).to be_valid
  end

  it "defaults sent_by_band to false" do
    expect(create(:direct_message).sent_by_band).to be false
  end

  it "is destroyed when its thread is destroyed" do
    message = create(:direct_message)
    thread = message.direct_message_thread

    thread.destroy

    expect(DirectMessage.exists?(message.id)).to be false
  end
end
