require "rails_helper"

RSpec.describe SpotifyClient do
  subject(:client) { described_class.new }

  def stub_http_response(body:, success: true)
    response = instance_double(Net::HTTPResponse, body: body.to_json, code: success ? "200" : "500")
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(success)
    allow(Net::HTTP).to receive(:start).and_return(response)
  end

  before do
    allow(client).to receive(:access_token).and_return("fake-token")
  end

  describe "#search_albums" do
    it "returns an empty array for a blank query" do
      expect(client.search_albums("")).to eq([])
    end

    it "maps Spotify's search response into AlbumResult structs" do
      stub_http_response(body: {
        albums: {
          items: [
            {
              id: "abc123",
              name: "Discovery",
              artists: [ { name: "Daft Punk" } ],
              images: [ { url: "https://example.com/cover.jpg" } ],
              release_date: "2001-03-12"
            }
          ]
        }
      })

      results = client.search_albums("Discovery")

      expect(results.size).to eq(1)
      expect(results.first).to have_attributes(
        spotify_id: "abc123",
        name: "Discovery",
        artist: "Daft Punk",
        image_url: "https://example.com/cover.jpg",
        release_year: "2001"
      )
    end

    it "raises SpotifyClient::Error when the request fails" do
      stub_http_response(body: {}, success: false)

      expect { client.search_albums("Discovery") }.to raise_error(SpotifyClient::Error)
    end
  end

  describe "#fetch_album" do
    it "maps Spotify's album response into AlbumDetails with ordered tracks" do
      stub_http_response(body: {
        name: "Discovery",
        tracks: {
          items: [
            { name: "One More Time", track_number: 1, external_urls: { spotify: "https://open.spotify.com/track/0DiWol3AO6WpXZgp0goxAV" } },
            { name: "Aerodynamic", track_number: 2, external_urls: { spotify: "https://open.spotify.com/track/2xLMifQCjDGFmkHkpNLD9h" } }
          ]
        }
      })

      album = client.fetch_album("abc123")

      expect(album.name).to eq("Discovery")
      expect(album.tracks.size).to eq(2)
      expect(album.tracks.first).to have_attributes(
        title: "One More Time",
        track_number: 1,
        spotify_url: "https://open.spotify.com/track/0DiWol3AO6WpXZgp0goxAV"
      )
    end

    it "raises SpotifyClient::Error when the request fails" do
      stub_http_response(body: {}, success: false)

      expect { client.fetch_album("abc123") }.to raise_error(SpotifyClient::Error)
    end
  end
end
