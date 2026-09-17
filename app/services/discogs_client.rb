require "net/http"

class DiscogsClient
  Error = Class.new(StandardError)
  ConfigurationError = Class.new(Error)

  API_BASE_URL = "https://api.discogs.com"
  USER_AGENT = "SceneCore/1.0 +https://github.com/urieljuliatti85/scenecore"
  OPEN_TIMEOUT = 3
  READ_TIMEOUT = 5

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

  ReleaseResult = Struct.new(
    :discogs_release_id,
    :title,
    :artist,
    :year,
    :format,
    :label,
    :catalog_number,
    :country,
    keyword_init: true
  )

  ReleaseDetails = Struct.new(
    :discogs_release_id,
    :title,
    :artist,
    :year,
    :format,
    :label,
    :catalog_number,
    :barcode,
    :country,
    :discogs_url,
    :metadata,
    keyword_init: true
  )

  def search_releases(query)
    return [] if query.blank?

    response = get("/database/search", q: query, type: "release", per_page: 10)

    response.fetch("results", []).filter_map do |item|
      release_id = item["id"]
      next if release_id.blank?

      artist, title = split_title(item["title"])

      ReleaseResult.new(
        discogs_release_id: release_id,
        title: title,
        artist: artist,
        year: item["year"],
        format: Array(item["format"]).join(", ").presence,
        label: Array(item["label"]).first,
        catalog_number: Array(item["catno"]).first,
        country: item["country"]
      )
    end
  end

  def fetch_release(release_id)
    unless release_id.to_s.match?(/\A\d+\z/)
      raise Error, "Invalid Discogs release id"
    end

    response = get("/releases/#{release_id}")
    artist = Array(response["artists"]).map { |entry| entry["name"] }.compact.join(", ").presence
    formats = Array(response["formats"]).map { |entry| format_name(entry) }.compact
    labels = Array(response["labels"])
    identifiers = Array(response["identifiers"])

    ReleaseDetails.new(
      discogs_release_id: response.fetch("id"),
      title: response.fetch("title"),
      artist: artist,
      year: response["year"],
      format: formats.join(", ").presence,
      label: labels.first&.fetch("name", nil),
      catalog_number: labels.first&.fetch("catno", nil),
      barcode: barcode_from(identifiers),
      country: response["country"],
      discogs_url: response["uri"].presence || "https://www.discogs.com/release/#{response.fetch('id')}",
      metadata: metadata_from(response, identifiers)
    )
  rescue KeyError
    raise Error, "Discogs returned an incomplete release"
  end

  private

  def get(path, **params)
    uri = URI("#{API_BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params) if params.present?

    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = USER_AGENT
    request["Authorization"] = authorization_header

    response = perform(uri, request)
    raise Error, "Discogs API request failed: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    parse(response)
  end

  def authorization_header
    token = credential(:token, "DISCOGS_TOKEN")
    return "Discogs token=#{token}" if token

    key = credential(:consumer_key, "DISCOGS_CONSUMER_KEY")
    secret = credential(:consumer_secret, "DISCOGS_CONSUMER_SECRET")
    return "Discogs key=#{key}, secret=#{secret}" if key && secret

    raise ConfigurationError, "Discogs API credentials are not configured"
  end

  def credential(name, env_name)
    Rails.application.credentials.dig(:discogs, name).presence || ENV[env_name].presence
  end

  def perform(uri, request)
    Net::HTTP.start(
      uri.host, uri.port,
      use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT
    ) { |http| http.request(request) }
  rescue *NETWORK_ERRORS => e
    raise Error, "Discogs request failed: #{e.class}"
  end

  def parse(response)
    JSON.parse(response.body)
  rescue JSON::ParserError
    raise Error, "Discogs returned an unreadable response"
  end

  def split_title(value)
    artist, title = value.to_s.split(" - ", 2)
    return [ nil, artist.presence ] if title.blank?

    [ artist.presence, title.presence ]
  end

  def format_name(entry)
    name = entry["name"].presence
    descriptions = Array(entry["descriptions"]).compact
    return name if descriptions.empty?

    [ name, descriptions.join(" / ") ].compact.join(" · ")
  end

  def barcode_from(identifiers)
    identifiers.find { |identifier| identifier["type"].to_s.casecmp("Barcode").zero? }&.fetch("value", nil)
  end

  def metadata_from(response, identifiers)
    {
      "country" => response["country"],
      "released" => response["released"],
      "genres" => Array(response["genres"]),
      "styles" => Array(response["styles"]),
      "identifiers" => identifiers.filter_map do |identifier|
        type = identifier["type"].presence
        value = identifier["value"].presence
        { "type" => type, "value" => value } if type && value
      end
    }.compact
  end
end
