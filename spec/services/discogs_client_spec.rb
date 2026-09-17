require "rails_helper"

RSpec.describe DiscogsClient do
  subject(:client) { described_class.new }

  def stub_http_response(body:, success: true)
    response = instance_double(Net::HTTPResponse, body: body.to_json, code: success ? "200" : "500")
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(success)
    allow(Net::HTTP).to receive(:start).and_return(response)
  end

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:discogs, :token).and_return("fake-discogs-token")
  end

  describe "#search_releases" do
    it "returns an empty array for a blank query" do
      expect(client.search_releases("")).to eq([])
    end

    it "maps Discogs release search results" do
      stub_http_response(body: {
        results: [
          {
            id: 123,
            title: "Band Name - Record Name",
            year: "2026",
            format: [ "Vinyl", "LP" ],
            label: [ "Scene Records" ],
            catno: [ "SC-001" ],
            country: "Brazil"
          }
        ]
      })

      release = client.search_releases("Record Name").first

      expect(release).to have_attributes(
        discogs_release_id: 123,
        title: "Record Name",
        artist: "Band Name",
        year: "2026",
        format: "Vinyl, LP",
        label: "Scene Records",
        catalog_number: "SC-001",
        country: "Brazil"
      )
    end
  end

  describe "#fetch_release" do
    it "maps release metadata without importing images or marketplace data" do
      stub_http_response(body: {
        id: 123,
        title: "Record Name",
        artists: [ { name: "Band Name" } ],
        year: 2026,
        country: "Brazil",
        released: "2026-09-17",
        uri: "https://www.discogs.com/release/123-Band-Name-Record-Name",
        formats: [ { name: "Vinyl", descriptions: [ "LP", "Album" ] } ],
        labels: [ { name: "Scene Records", catno: "SC-001" } ],
        identifiers: [ { type: "Barcode", value: "7891234567890" } ],
        genres: [ "Rock" ],
        styles: [ "Crust" ],
        images: [ { uri: "https://example.com/restricted-cover.jpg" } ],
        lowest_price: 25.0
      })

      release = client.fetch_release(123)

      expect(release).to have_attributes(
        discogs_release_id: 123,
        title: "Record Name",
        artist: "Band Name",
        year: 2026,
        format: "Vinyl · LP / Album",
        label: "Scene Records",
        catalog_number: "SC-001",
        barcode: "7891234567890"
      )
      expect(release.metadata).to include("genres" => [ "Rock" ], "styles" => [ "Crust" ])
      expect(release.metadata).not_to have_key("images")
      expect(release.metadata).not_to have_key("lowest_price")
    end

    it "rejects an invalid release id before making a request" do
      expect(Net::HTTP).not_to receive(:start)

      expect { client.fetch_release("not-an-id") }.to raise_error(DiscogsClient::Error)
    end
  end

  describe "configuration" do
    it "uses consumer key and secret when a personal token is not configured" do
      allow(Rails.application.credentials).to receive(:dig).and_return(nil)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("DISCOGS_TOKEN").and_return(nil)
      allow(ENV).to receive(:[]).with("DISCOGS_CONSUMER_KEY").and_return("consumer-key")
      allow(ENV).to receive(:[]).with("DISCOGS_CONSUMER_SECRET").and_return("consumer-secret")
      stub_http_response(body: { results: [] })

      client.search_releases("Record")

      expect(Net::HTTP).to have_received(:start)
    end

    it "raises a configuration error when no credentials are available" do
      allow(Rails.application.credentials).to receive(:dig).and_return(nil)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("DISCOGS_TOKEN").and_return(nil)
      allow(ENV).to receive(:[]).with("DISCOGS_CONSUMER_KEY").and_return(nil)
      allow(ENV).to receive(:[]).with("DISCOGS_CONSUMER_SECRET").and_return(nil)

      expect { client.search_releases("Record") }.to raise_error(DiscogsClient::ConfigurationError)
    end
  end

  describe "network failures" do
    DiscogsClient::NETWORK_ERRORS.each do |error_class|
      it "converts #{error_class} into DiscogsClient::Error" do
        allow(Net::HTTP).to receive(:start).and_raise(error_class)

        expect { client.fetch_release(123) }.to raise_error(DiscogsClient::Error)
      end
    end
  end
end
