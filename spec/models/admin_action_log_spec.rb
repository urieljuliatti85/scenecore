require "rails_helper"

RSpec.describe AdminActionLog, type: :model do
  it "is valid with valid attributes" do
    expect(build(:admin_action_log)).to be_valid
  end

  it "requires an action" do
    log = build(:admin_action_log, action: nil)

    expect(log).not_to be_valid
  end

  it "requires an actor" do
    log = build(:admin_action_log, actor: nil)

    expect(log).not_to be_valid
  end

  it "requires a subject" do
    log = build(:admin_action_log, subject: nil)

    expect(log).not_to be_valid
  end

  it "accepts any record as its polymorphic subject" do
    band = create(:band)
    log = create(:admin_action_log, subject: band)

    expect(log.subject).to eq(band)
    expect(log.subject_type).to eq("Band")
  end
end
