require "rails_helper"

RSpec.describe "Ticket batches", type: :request do
  it "lets a band administrator create a ticket batch" do
    administrator = create(:user)
    event = create(:event)
    create(:band_membership, :administrator, user: administrator, band: event.band)
    sign_in administrator

    expect {
      post band_event_ticket_batches_path(event.band, event), params: {
        ticket_batch: { name: "General admission", price_cents: 2_500, quantity_total: 50 }
      }
    }.to change(TicketBatch, :count).by(1)

    expect(response).to redirect_to(band_event_path(event.band, event))
  end

  it "does not let a plain band member create a ticket batch" do
    member = create(:user)
    event = create(:event)
    create(:band_membership, user: member, band: event.band)
    sign_in member

    expect {
      post band_event_ticket_batches_path(event.band, event), params: {
        ticket_batch: { name: "General admission", price_cents: 2_500, quantity_total: 50 }
      }
    }.not_to change(TicketBatch, :count)

    expect(response).to redirect_to(root_path)
  end

  it "lets a band administrator configure membership presale dates" do
    administrator = create(:user)
    event = create(:event)
    create(:band_membership, :administrator, user: administrator, band: event.band)
    sign_in administrator
    public_start = 5.days.from_now.change(usec: 0)

    post band_event_ticket_batches_path(event.band, event), params: {
      ticket_batch: {
        name: "Member presale", price_cents: 2_500, quantity_total: 50,
        sales_start_at: public_start,
        fan_sales_start_at: public_start - 1.day,
        supporter_sales_start_at: public_start - 2.days,
        core_member_sales_start_at: public_start - 3.days
      }
    }

    batch = TicketBatch.last
    expect(batch.fan_sales_start_at).to eq(public_start - 1.day)
    expect(batch.supporter_sales_start_at).to eq(public_start - 2.days)
    expect(batch.core_member_sales_start_at).to eq(public_start - 3.days)
  end
end
