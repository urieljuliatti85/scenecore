require "rails_helper"

RSpec.describe TicketPolicy do
  let(:ticket) { create(:ticket) }

  it "allows a member of the event's band to check in" do
    member = create(:user)
    create(:band_membership, user: member, band: ticket.event.band)

    expect(described_class.new(member, ticket)).to be_check_in
  end

  it "allows a band administrator to check in" do
    administrator = create(:user)
    create(:band_membership, :administrator, user: administrator, band: ticket.event.band)

    expect(described_class.new(administrator, ticket)).to be_check_in
  end

  it "does not let a platform administrator check in without band membership" do
    platform_admin = create(:user, :platform_admin)

    expect(described_class.new(platform_admin, ticket)).not_to be_check_in
  end

  it "does not let a member of another band check in" do
    outsider = create(:user)
    create(:band_membership, user: outsider, band: create(:band))

    expect(described_class.new(outsider, ticket)).not_to be_check_in
  end
end
