require "rails_helper"

RSpec.describe Report, type: :model do
  it "is valid with valid attributes" do
    expect(build(:report)).to be_valid
  end

  it "requires a reason" do
    expect(build(:report, reason: nil)).not_to be_valid
  end

  it "requires a reporter" do
    expect(build(:report, reporter: nil)).not_to be_valid
  end

  it "requires a reportable" do
    expect(build(:report, reportable: nil)).not_to be_valid
  end

  it "defaults status to pending" do
    expect(create(:report).status).to eq("pending")
  end

  it "restricts status to pending, resolved, or dismissed" do
    report = build(:report)
    report.status = "escalated"

    expect(report).not_to be_valid
  end

  it "can report a comment" do
    comment = create(:comment)

    expect(build(:report, reportable: comment)).to be_valid
  end
end
