require "rails_helper"

RSpec.describe GoogleAnalyticsClient do
  describe ".configured?" do
    around do |example|
      original_property = ENV["GOOGLE_ANALYTICS_PROPERTY_ID"]
      example.run
      ENV["GOOGLE_ANALYTICS_PROPERTY_ID"] = original_property
    end

    it "is false when the property id is not set" do
      ENV["GOOGLE_ANALYTICS_PROPERTY_ID"] = nil

      expect(described_class.configured?).to be false
    end

    it "is false when the property id is set but the credentials file is missing" do
      ENV["GOOGLE_ANALYTICS_PROPERTY_ID"] = "123456"
      allow(described_class::CREDENTIALS_PATH).to receive(:exist?).and_return(false)

      expect(described_class.configured?).to be false
    end

    it "is true when both the property id and the credentials file are present" do
      ENV["GOOGLE_ANALYTICS_PROPERTY_ID"] = "123456"
      allow(described_class::CREDENTIALS_PATH).to receive(:exist?).and_return(true)

      expect(described_class.configured?).to be true
    end
  end

  describe "#summary" do
    it "raises when Google Analytics is not configured" do
      allow(described_class).to receive(:configured?).and_return(false)

      expect { described_class.new.summary }.to raise_error(described_class::Error, /not configured/)
    end
  end
end
