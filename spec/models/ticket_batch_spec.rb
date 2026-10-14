require "rails_helper"

RSpec.describe TicketBatch, type: :model do
  it "counts paid tickets and live reservations against availability" do
    batch = create(:ticket_batch, quantity_total: 6)
    create(:ticket_order, :paid, ticket_batch: batch, quantity: 2,
                                unit_price_cents: batch.price_cents,
                                total_cents: batch.price_cents * 2)
    create(:ticket_order, ticket_batch: batch, quantity: 3,
                          unit_price_cents: batch.price_cents,
                          total_cents: batch.price_cents * 3,
                          expires_at: 10.minutes.from_now)

    expect(batch.remaining_quantity).to eq(1)
  end

  it "releases expired reservations" do
    batch = create(:ticket_batch, quantity_total: 2)
    create(:ticket_order, ticket_batch: batch, quantity: 2,
                          unit_price_cents: batch.price_cents,
                          total_cents: batch.price_cents * 2,
                          expires_at: 1.minute.ago)

    expect(batch.remaining_quantity).to eq(2)
  end

  it "is not on sale before its sales window" do
    batch = create(:ticket_batch, sales_start_at: 1.hour.from_now)

    expect(batch).not_to be_on_sale
  end

  it "cannot shrink below sold and currently reserved tickets" do
    batch = create(:ticket_batch, quantity_total: 5)
    create(:ticket_order, :paid, ticket_batch: batch, quantity: 3,
                                unit_price_cents: batch.price_cents,
                                total_cents: batch.price_cents * 3)

    expect(batch.update(quantity_total: 2)).to be(false)
    expect(batch.errors[:quantity_total]).to include("cannot be lower than 3 sold or reserved tickets")
  end

  describe "membership presales" do
    let(:band) { create(:band, :approved) }
    let(:event) { create(:event, :published, band: band, starts_at: 10.days.from_now) }
    let(:public_start) { 4.days.from_now.change(usec: 0) }
    let(:batch) do
      create(
        :ticket_batch,
        event: event,
        sales_start_at: public_start,
        fan_sales_start_at: public_start - 1.day,
        supporter_sales_start_at: public_start - 2.days,
        core_member_sales_start_at: public_start - 3.days
      )
    end

    let(:fan) { create(:user) }
    let(:supporter) { create(:user) }
    let(:core_member) { create(:user) }

    before do
      create(:membership, band: band, user: fan, level: :fan)
      create(:membership, band: band, user: supporter, level: :supporter)
      create(:membership, band: band, user: core_member, level: :core_member)
    end

    it "opens first to Core Member, then Supporter, Fan, and the public" do
      travel_to(public_start - 4.days) do
        expect(batch).not_to be_on_sale_to(core_member)
      end

      travel_to(public_start - 3.days) do
        expect(batch).to be_on_sale_to(core_member)
        expect(batch).not_to be_on_sale_to(supporter)
        expect(batch).not_to be_on_sale_to(fan)
        expect(batch).not_to be_on_sale_to(nil)
      end

      travel_to(public_start - 2.days) do
        expect(batch).to be_on_sale_to(core_member)
        expect(batch).to be_on_sale_to(supporter)
        expect(batch).not_to be_on_sale_to(fan)
        expect(batch).not_to be_on_sale_to(nil)
      end

      travel_to(public_start - 1.day) do
        expect(batch).to be_on_sale_to(core_member)
        expect(batch).to be_on_sale_to(supporter)
        expect(batch).to be_on_sale_to(fan)
        expect(batch).not_to be_on_sale_to(nil)
      end

      travel_to(public_start) do
        expect(batch).to be_on_sale_to(core_member)
        expect(batch).to be_on_sale_to(supporter)
        expect(batch).to be_on_sale_to(fan)
        expect(batch).to be_on_sale_to(nil)
      end
    end

    it "does not grant presale access for inactive or other-band memberships" do
      other_band_member = create(:user)
      create(:membership, band: create(:band, :approved), user: other_band_member, level: :core_member)
      inactive_members = %i[paused cancelled expired].map do |status|
        user = create(:user)
        create(:membership, status, band: band, user: user, level: :core_member)
        user
      end

      travel_to(public_start - 3.days) do
        inactive_members.each { |user| expect(batch).not_to be_on_sale_to(user) }
        expect(batch).not_to be_on_sale_to(other_band_member)
      end
    end

    it "applies upgrades and downgrades immediately to future reservations" do
      membership = band.memberships.find_by!(user: fan)

      travel_to(public_start - 2.days) do
        expect(batch).not_to be_on_sale_to(fan)
        membership.update!(level: :supporter)
        expect(batch).to be_on_sale_to(fan)
        membership.update!(level: :fan)
        expect(batch).not_to be_on_sale_to(fan)
      end
    end

    it "falls back to the closest eligible configured window" do
      batch.update!(core_member_sales_start_at: nil)

      expect(batch.sale_starts_at_for(core_member)).to eq(batch.supporter_sales_start_at)
    end

    it "rejects presales without a public start" do
      batch.sales_start_at = nil

      expect(batch).not_to be_valid
      expect(batch.errors[:sales_start_at]).to include("is required when membership early access is configured")
    end

    it "rejects dates outside membership hierarchy order" do
      batch.core_member_sales_start_at = batch.supporter_sales_start_at + 1.hour

      expect(batch).not_to be_valid
      expect(batch.errors[:base]).to include("membership sales must open in Core Member, Supporter, Fan, then public order")
    end
  end
end
