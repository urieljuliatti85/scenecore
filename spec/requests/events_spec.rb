require "rails_helper"

RSpec.describe "Events", type: :request do
  describe "GET /bands/:band_id/events/:id" do
    it "requires authentication" do
      event = create(:event)

      get band_event_path(event.band, event)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the event to a band member" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      event = create(:event, band: band, title: "Album release show", location: "Circo Voador, Rio de Janeiro")
      sign_in user

      get band_event_path(band, event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Album release show")
      expect(response.body).to include("Circo Voador, Rio de Janeiro")
    end

    it "prevents a member of another band from viewing the event" do
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      event = create(:event)
      sign_in outsider

      get band_event_path(event.band, event)

      expect(response).to redirect_to(root_path)
    end

    it "does not expose an event belonging to a different band" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      other_event = create(:event)
      sign_in user

      get band_event_path(band, other_event)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /bands/:band_id/events" do
    it "creates an event for a band member" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      expect {
        post band_events_path(band), params: { event: { title: "Album release show", location: "Circo Voador, Rio de Janeiro", starts_at: 1.month.from_now, ticket_url: "https://example.com/tickets" } }
      }.to change(Event, :count).by(1)

      expect(Event.last.band).to eq(band)
      expect(response).to redirect_to(band_path(band))
    end

    it "does not create an event without a title" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      expect {
        post band_events_path(band), params: { event: { title: "", location: "Somewhere", starts_at: 1.month.from_now } }
      }.not_to change(Event, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "requires authentication" do
      band = create(:band)

      expect {
        post band_events_path(band), params: { event: { title: "Show" } }
      }.not_to change(Event, :count)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "prevents a member of another band from creating an event" do
      band = create(:band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      expect {
        post band_events_path(band), params: { event: { title: "Show" } }
      }.not_to change(Event, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /bands/:band_id/events/:id" do
    it "allows a band member to update an event" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      event = create(:event, band: band, title: "Old title")
      sign_in user

      patch band_event_path(band, event), params: { event: { title: "New title" } }

      expect(event.reload.title).to eq("New title")
      expect(response).to redirect_to(band_path(band))
    end

    it "prevents a member of another band from updating the event" do
      band = create(:band)
      event = create(:event, band: band, title: "Old title")
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      patch band_event_path(band, event), params: { event: { title: "Hijacked" } }

      expect(event.reload.title).to eq("Old title")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /bands/:band_id/events/:id" do
    it "allows a band member to delete an event" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      event = create(:event, band: band)
      sign_in user

      expect {
        delete band_event_path(band, event)
      }.to change(Event, :count).by(-1)

      expect(response).to redirect_to(band_path(band))
    end

    it "prevents a member of another band from deleting the event" do
      band = create(:band)
      event = create(:event, band: band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      expect {
        delete band_event_path(band, event)
      }.not_to change(Event, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /bands/:band_id/events/:id/publish" do
    it "publishes the event" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      event = create(:event, band: band)
      sign_in user

      patch publish_band_event_path(band, event)

      expect(event.reload.status).to eq("published")
    end

    it "prevents a member of another band from publishing the event" do
      band = create(:band)
      event = create(:event, band: band)
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)
      sign_in outsider

      patch publish_band_event_path(band, event)

      expect(event.reload.status).to eq("draft")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /bands/:band_id/events/:id/unpublish" do
    it "unpublishes the event" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      event = create(:event, :published, band: band)
      sign_in user

      patch unpublish_band_event_path(band, event)

      expect(event.reload.status).to eq("draft")
    end
  end
end
