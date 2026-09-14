require "net/http"

# Talks to Spotify's Web API using the Client Credentials flow — this is
# read-only access to public catalog data (search, album/track metadata),
# so it never needs a user to authorize anything via Spotify's own login.
class SpotifyClient
  Error = Class.new(StandardError)

  ACCOUNTS_BASE_URL = "https://accounts.spotify.com"
  API_BASE_URL = "https://api.spotify.com/v1"
  TOKEN_CACHE_KEY = "spotify_client/access_token"

  AlbumResult = Struct.new(:spotify_id, :name, :artist, :image_url, :release_year, keyword_init: true)
  AlbumDetails = Struct.new(:name, :cover_image_url, :tracks, keyword_init: true)
  TrackDetails = Struct.new(:title, :track_number, :spotify_url, keyword_init: true)

  def search_albums(query)
    return [] if query.blank?

    response = get("/search", q: query, type: "album", limit: 10)
    response.fetch("albums", {}).fetch("items", []).map do |item|
      AlbumResult.new(
        spotify_id: item["id"],
        name: item["name"],
        artist: item.dig("artists", 0, "name"),
        image_url: item.dig("images", 0, "url"),
        release_year: item["release_date"].to_s[0, 4]
      )
    end
  end

  def fetch_album(spotify_id)
    response = get("/albums/#{spotify_id}")

    tracks = response.fetch("tracks", {}).fetch("items", []).map do |item|
      TrackDetails.new(
        title: item["name"],
        track_number: item["track_number"],
        spotify_url: item.dig("external_urls", "spotify")
      )
    end

    AlbumDetails.new(name: response["name"], cover_image_url: response.dig("images", 0, "url"), tracks: tracks)
  end

  private

  def get(path, **params)
    uri = URI("#{API_BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params) if params.present?

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{access_token}"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
    raise Error, "Spotify API request failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def access_token
    Rails.cache.fetch(TOKEN_CACHE_KEY, expires_in: 50.minutes) { request_access_token }
  end

  def request_access_token
    uri = URI("#{ACCOUNTS_BASE_URL}/api/token")
    credentials = Rails.application.credentials.spotify

    request = Net::HTTP::Post.new(uri)
    request.basic_auth(credentials[:client_id], credentials[:client_secret])
    request.set_form_data(grant_type: "client_credentials")

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
    raise Error, "Spotify authentication failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body).fetch("access_token")
  end
end
