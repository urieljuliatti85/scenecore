require "net/http"

# Talks to Spotify's Web API using the Client Credentials flow — this is
# read-only access to public catalog data (search, album/track metadata),
# so it never needs a user to authorize anything via Spotify's own login.
class SpotifyClient
  Error = Class.new(StandardError)

  ACCOUNTS_BASE_URL = "https://accounts.spotify.com"
  API_BASE_URL = "https://api.spotify.com/v1"
  TOKEN_CACHE_KEY = "spotify_client/access_token"

  # Deliberately short: these calls happen inside a web request, and Puma
  # runs 3 threads per process, so a slow Spotify would otherwise tie up
  # the whole app waiting on Ruby's 60s default.
  OPEN_TIMEOUT = 3
  READ_TIMEOUT = 5

  # Every way the connection itself can fail. Without this they escape as
  # raw exceptions and the callers' `rescue Error` misses them, turning a
  # Spotify outage into a 500.
  NETWORK_ERRORS = [
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::EHOSTUNREACH,
    Errno::ENETUNREACH,
    IOError,
    Net::OpenTimeout,
    Net::ReadTimeout,
    OpenSSL::SSL::SSLError,
    SocketError
  ].freeze

  AlbumResult = Struct.new(:spotify_id, :name, :artist, :image_url, :release_year, keyword_init: true)
  AlbumDetails = Struct.new(:name, :cover_image_url, keyword_init: true)
  ArtistResult = Struct.new(:spotify_id, :name, :image_url, :spotify_url, keyword_init: true)

  # Used to prefill a new band's details from its Spotify profile. The
  # external_urls link is taken from Spotify's own response rather than
  # built from the id, so the band is never sent to a URL Spotify did
  # not give us.
  def search_artists(query)
    return [] if query.blank?

    response = get("/search", q: query, type: "artist", limit: 10)
    response.fetch("artists", {}).fetch("items", []).map do |item|
      ArtistResult.new(
        spotify_id: item["id"],
        name: item["name"],
        image_url: item.dig("images", 0, "url"),
        spotify_url: item.dig("external_urls", "spotify")
      )
    end
  end

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

  # Only the album itself: SceneCore links out to Spotify rather than
  # mirroring its track listing, so the tracks in this response are not
  # read.
  def fetch_album(spotify_id)
    response = get("/albums/#{spotify_id}")

    AlbumDetails.new(name: response["name"], cover_image_url: response.dig("images", 0, "url"))
  end

  private

  def get(path, **params)
    uri = URI("#{API_BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params) if params.present?

    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{access_token}"

    response = perform(uri, request)
    raise Error, "Spotify API request failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    parse(response)
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

    response = perform(uri, request)
    raise Error, "Spotify authentication failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    parse(response).fetch("access_token")
  end

  def perform(uri, request)
    Net::HTTP.start(
      uri.host, uri.port,
      use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT
    ) { |http| http.request(request) }
  rescue *NETWORK_ERRORS => e
    raise Error, "Spotify request failed: #{e.class}"
  end

  def parse(response)
    JSON.parse(response.body)
  rescue JSON::ParserError
    raise Error, "Spotify returned an unreadable response"
  end
end
