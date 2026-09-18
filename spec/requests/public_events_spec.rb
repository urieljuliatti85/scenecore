require "rails_helper"

RSpec.describe "Public events", type: :request do
  it "shows a published approved-band event and its ticket batches without authentication" do
    band = create(:band, :approved)
    event = create(:event, :published, band: band, title: "SceneCore Fest")
    create(:ticket_batch, event: event, name: "First release", price_cents: 3_000)

    get public_event_path(band.slug, event)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("SceneCore Fest")
    expect(response.body).to include("First release")
    expect(response.body).to include("US$30.00")
  end

  it "does not expose a draft event" do
    band = create(:band, :approved)
    event = create(:event, band: band)

    get public_event_path(band.slug, event)

    expect(response).to have_http_status(:not_found)
  end
end
