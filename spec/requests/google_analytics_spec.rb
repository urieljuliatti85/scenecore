require "rails_helper"

RSpec.describe "Google Analytics integration", type: :request do
  around do |example|
    original = ENV["GOOGLE_ANALYTICS_ID"]
    example.run
    ENV["GOOGLE_ANALYTICS_ID"] = original
  end

  it "does not render the GA script or cookie banner when no id is configured" do
    ENV["GOOGLE_ANALYTICS_ID"] = nil

    get root_path

    expect(response.body).not_to include("googletagmanager.com")
    expect(response.body).not_to include("We use cookies")
  end

  it "renders the GA script with consent mode denied by default when an id is configured" do
    ENV["GOOGLE_ANALYTICS_ID"] = "G-VM67T9TMKE"

    get root_path

    expect(response.body).to include("googletagmanager.com/gtag/js?id=G-VM67T9TMKE")
    expect(response.body).to include('gtag("consent", "default", { analytics_storage: "denied" });')
    expect(response.body).to include('gtag("config", "G-VM67T9TMKE");')
  end

  it "renders the cookie consent banner when an id is configured" do
    ENV["GOOGLE_ANALYTICS_ID"] = "G-VM67T9TMKE"

    get root_path

    expect(response.body).to include("We use cookies")
  end

  it "refuses to render a malformed measurement id" do
    ENV["GOOGLE_ANALYTICS_ID"] = "\"></script><script>alert(1)</script>"

    get root_path

    expect(response.body).not_to include("<script>alert(1)</script>")
    expect(response.body).not_to include("googletagmanager.com")
  end
end
