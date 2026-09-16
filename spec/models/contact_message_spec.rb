require "rails_helper"

RSpec.describe ContactMessage do
  subject(:message) { described_class.new(name: "Ana", email: "ana@example.com", message: "Hello") }

  it "is valid with name, email and message" do
    expect(message).to be_valid
  end

  it "is valid without a band" do
    message.band = nil

    expect(message).to be_valid
  end

  it "requires a name" do
    message.name = ""

    expect(message).not_to be_valid
  end

  it "requires a message" do
    message.message = ""

    expect(message).not_to be_valid
  end

  it "requires a well-formed email" do
    message.email = "nope"

    expect(message).not_to be_valid
    expect(message.errors[:email]).to include("must be a valid email address")
  end

  it "rejects a message longer than the limit" do
    message.message = "a" * (described_class::MESSAGE_MAX_LENGTH + 1)

    expect(message).not_to be_valid
  end
end
