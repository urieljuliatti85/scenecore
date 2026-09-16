require "rails_helper"

RSpec.describe RemoteImageFetcher do
  subject(:fetcher) { described_class.new }

  describe "#call" do
    it "rejects a non-HTTP scheme" do
      expect { fetcher.call("file:///etc/passwd") }
        .to raise_error(described_class::Error, /valid image URL/)
    end

    it "rejects a malformed URL" do
      expect { fetcher.call("not a url") }
        .to raise_error(described_class::Error, /valid image URL/)
    end

    it "rejects a blank URL" do
      expect { fetcher.call("") }
        .to raise_error(described_class::Error, /valid image URL/)
    end

    # The SSRF cases: a URL the server fetches on a user's behalf must
    # never be able to reach the cloud metadata endpoint or anything on
    # the private network.
    it "rejects the cloud metadata endpoint" do
      expect { fetcher.call("http://169.254.169.254/latest/meta-data/") }
        .to raise_error(described_class::Error, /not publicly reachable/)
    end

    it "rejects loopback" do
      expect { fetcher.call("http://127.0.0.1:3000/internal") }
        .to raise_error(described_class::Error, /not publicly reachable/)
    end

    it "rejects a private network address" do
      expect { fetcher.call("http://10.0.0.1/secret") }
        .to raise_error(described_class::Error, /not publicly reachable/)
    end

    it "rejects a public hostname that resolves to a private address" do
      allow(Resolv).to receive(:getaddresses).with("sneaky.example.com").and_return([ "192.168.1.1" ])

      expect { fetcher.call("https://sneaky.example.com/cover.png") }
        .to raise_error(described_class::Error, /not publicly reachable/)
    end

    it "rejects a hostname that does not resolve" do
      allow(Resolv).to receive(:getaddresses).and_return([])

      expect { fetcher.call("https://nowhere.example.com/cover.png") }
        .to raise_error(described_class::Error, /could not be reached/)
    end
  end
end
