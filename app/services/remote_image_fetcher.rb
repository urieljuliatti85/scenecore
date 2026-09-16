require "net/http"
require "resolv"

# Downloads an image from a user-supplied URL so it can be attached as an
# album cover.
#
# A user-supplied URL fetched by the server is an SSRF vector: without
# checks, someone can point it at the cloud metadata endpoint
# (169.254.169.254) or at Railway's private network and have the app
# fetch it on their behalf. Every guard here exists for that reason:
#
# - only http/https, so file:// and friends can't be used;
# - the resolved IP must be a public address, re-checked on each redirect
#   (a public hostname can resolve to, or redirect to, a private one);
# - redirects are followed manually and capped, so Net::HTTP can't follow
#   one past the IP check;
# - the response must be an image type HasImage accepts, and is truncated
#   at the same size limit rather than read unbounded into memory.
class RemoteImageFetcher
  Error = Class.new(StandardError)

  MAX_REDIRECTS = 3
  OPEN_TIMEOUT = 3
  READ_TIMEOUT = 5

  Result = Struct.new(:io, :filename, :content_type, keyword_init: true)

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

  def call(raw_url)
    uri = parse(raw_url)
    content_type, body = fetch(uri)

    unless content_type.in?(HasImage::IMAGE_CONTENT_TYPES)
      raise Error, "That URL is not a PNG, JPEG, or WebP image."
    end

    Result.new(
      io: StringIO.new(body),
      filename: filename_for(uri, content_type),
      content_type: content_type
    )
  end

  private

  def parse(raw_url)
    uri = URI.parse(raw_url.to_s.strip)
    raise Error, "Enter a valid image URL." unless uri.is_a?(URI::HTTP) && uri.host.present?

    uri
  rescue URI::InvalidURIError
    raise Error, "Enter a valid image URL."
  end

  # Returns [content_type, body]. The response is streamed inside the
  # open connection so read_limited can abort an oversized download
  # partway through — reading the body up front would defeat the limit.
  def fetch(uri, redirects_left = MAX_REDIRECTS)
    verify_public_address!(uri)

    start(uri) do |http|
      http.request(Net::HTTP::Get.new(uri)) do |response|
        case response
        when Net::HTTPSuccess
          return [ content_type_of(response), read_limited(response) ]
        when Net::HTTPRedirection
          raise Error, "That URL redirects too many times." if redirects_left.zero?

          location = response["location"].to_s
          raise Error, "That URL could not be followed." if location.blank?

          return fetch(parse(URI.join(uri, location).to_s), redirects_left - 1)
        else
          raise Error, "That URL could not be downloaded (#{response.code})."
        end
      end
    end
  end

  def content_type_of(response)
    response["content-type"].to_s.split(";").first.to_s.strip
  end

  # Resolves the hostname and rejects anything that is not a public
  # address. Checking the resolved IP rather than the hostname is what
  # stops a public name that points at an internal one.
  def verify_public_address!(uri)
    addresses = Resolv.getaddresses(uri.host)
    raise Error, "That URL could not be reached." if addresses.empty?

    addresses.each do |address|
      ip = IPAddr.new(address)

      if ip.loopback? || ip.private? || ip.link_local? || !ip.ipv4? && !ip.ipv6?
        raise Error, "That URL is not publicly reachable."
      end
    rescue IPAddr::InvalidAddressError
      raise Error, "That URL could not be reached."
    end
  end

  def start(uri, &block)
    Net::HTTP.start(uri.hostname, uri.port,
                    use_ssl: uri.scheme == "https",
                    open_timeout: OPEN_TIMEOUT,
                    read_timeout: READ_TIMEOUT, &block)
  rescue *NETWORK_ERRORS => e
    raise Error, "That URL could not be reached (#{e.class})."
  end

  # Reads at most one byte past the limit, so an oversized image is
  # rejected without pulling the whole thing into memory.
  def read_limited(response)
    body = +""

    response.read_body do |chunk|
      body << chunk

      if body.bytesize > HasImage::IMAGE_MAX_SIZE
        raise Error, "That image is larger than #{HasImage::IMAGE_MAX_SIZE / 1.megabyte}MB."
      end
    end

    body
  end

  def filename_for(uri, content_type)
    extension = content_type.split("/").last.sub("jpeg", "jpg")
    base = File.basename(uri.path.to_s, ".*").presence || "cover"

    "#{base.parameterize}.#{extension}"
  end
end
