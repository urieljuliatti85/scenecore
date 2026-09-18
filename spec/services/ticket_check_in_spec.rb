require "rails_helper"

RSpec.describe TicketCheckIn do
  it "records the validator exactly once" do
    ticket = create(:ticket)
    validator = create(:user)

    described_class.call(ticket, validator: validator)

    expect(ticket.reload).to be_used
    expect(ticket.checked_in_by).to eq(validator)
    expect { described_class.call(ticket, validator: validator) }
      .to raise_error(described_class::AlreadyUsed)
  end
end
