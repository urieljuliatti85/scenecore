require "rails_helper"

RSpec.describe "Band orders", type: :request do
  let(:band) { create(:band, :approved, name: "The Testers") }
  let(:admin) { create(:user) }
  let(:fan) { create(:user, name: "Buying Fan") }

  def order_for(band, status: :paid, with_address: true)
    order = create(:order, band: band, user: fan, status: status,
                           subtotal_cents: 12_000, shipping_cents: 1_500,
                           total_cents: 13_500, platform_fee_cents: 1_200)
    order.order_items.create!(product_name: "Vinyl", variant_name: "Standard",
                              unit_price_cents: 12_000, quantity: 1)
    if with_address
      ShippingAddress.create!(order: order, recipient_name: "Buying Fan", line1: "1 Main St",
                              city: "Springfield", state: "IL", postal_code: "62704", country: "US")
    end
    order
  end

  def sign_in_as_administrator
    create(:band_membership, :administrator, band: band, user: admin)
    sign_in admin
  end

  describe "the orders tab" do
    before { sign_in_as_administrator }

    # The address is the reason the band opens this at all, so it is shown
    # in the list rather than behind another click.
    it "lists orders awaiting fulfilment with the address to ship to" do
      order_for(band)

      get band_path(band, tab: "orders")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("To fulfil")
      expect(response.body).to include("1 Main St")
      expect(response.body).to include("Mark processing")
    end

    it "counts the orders awaiting fulfilment beside the tab label" do
      2.times { order_for(band) }

      get band_path(band, tab: "orders")

      tab = Nokogiri::HTML(response.body).css("a[href*='tab=orders']").text

      expect(tab).to include("2")
    end

    # A pending order has not been paid for. Showing it as work to do would
    # have the band posting goods nobody paid for.
    it "does not present a pending order as something to send" do
      order_for(band, status: :pending)

      get band_path(band, tab: "orders")

      expect(response.body).to include("Nothing waiting to be sent")
    end

    it "keeps finished orders visible as a record" do
      order_for(band, status: :completed)

      get band_path(band, tab: "orders")

      expect(response.body).to include("Everything else")
    end

    it "does not show another band's orders" do
      order_for(create(:band), status: :paid)

      get band_path(band, tab: "orders")

      expect(response.body).to include("Nothing waiting to be sent")
    end
  end

  describe "GET /bands/:band_id/orders/:id" do
    it "shows the band what it receives after commission" do
      sign_in_as_administrator
      order = order_for(band)

      get band_order_path(band, order)

      expect(response).to have_http_status(:ok)
      # 13,500 charged minus the 1,200 platform fee already taken.
      expect(response.body).to include("$123.00")
      expect(response.body).to include("Buying Fan")
    end

    it "refuses a band member who is not an administrator" do
      member = create(:user)
      create(:band_membership, band: band, user: member, role: :member)
      sign_in member
      order = order_for(band)

      get band_order_path(band, order)

      expect(response).to redirect_to(root_path)
    end

    # Scoped through the band, so another band's order id does not resolve
    # even before the policy runs.
    it "does not resolve an order belonging to another band" do
      sign_in_as_administrator
      other_order = order_for(create(:band))

      get band_order_path(band, other_order)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /bands/:band_id/orders/:id/fulfil" do
    it "advances the order and says so" do
      sign_in_as_administrator
      order = order_for(band)

      patch fulfil_band_order_path(band, order)

      expect(order.reload).to be_processing
      expect(flash[:notice]).to include("processing")
    end

    it "advances processing to completed" do
      sign_in_as_administrator
      order = order_for(band, status: :processing)

      patch fulfil_band_order_path(band, order)

      expect(order.reload).to be_completed
    end

    # Only the band ships, so only the band advances an order — the fan who
    # placed it can read it but not move it.
    it "does not let the fan who placed it advance it" do
      sign_in fan
      order = order_for(band)

      patch fulfil_band_order_path(band, order)

      expect(order.reload).to be_paid
    end

    it "does not let another band's administrator advance it" do
      outsider = create(:user)
      create(:band_membership, :administrator, band: create(:band), user: outsider)
      sign_in outsider
      order = order_for(band)

      patch fulfil_band_order_path(band, order)

      expect(order.reload).to be_paid
    end

    it "refuses to advance an order Stripe has not confirmed" do
      sign_in_as_administrator
      order = order_for(band, status: :pending)

      patch fulfil_band_order_path(band, order)

      expect(order.reload).to be_pending
    end

    it "refuses to advance a completed order" do
      sign_in_as_administrator
      order = order_for(band, status: :completed)

      patch fulfil_band_order_path(band, order)

      expect(order.reload).to be_completed
    end
  end
end
