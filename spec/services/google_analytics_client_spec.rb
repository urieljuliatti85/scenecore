require "rails_helper"

RSpec.describe GoogleAnalyticsClient do
  describe ".configured?" do
    around do |example|
      original_property = ENV["GOOGLE_ANALYTICS_PROPERTY_ID"]
      original_json = ENV["GOOGLE_ANALYTICS_CREDENTIALS_JSON"]
      example.run
      ENV["GOOGLE_ANALYTICS_PROPERTY_ID"] = original_property
      ENV["GOOGLE_ANALYTICS_CREDENTIALS_JSON"] = original_json
    end

    it "is false when the property id is not set" do
      ENV["GOOGLE_ANALYTICS_PROPERTY_ID"] = nil

      expect(described_class.configured?).to be false
    end

    it "is false when the property id is set but neither credentials source is present" do
      ENV["GOOGLE_ANALYTICS_PROPERTY_ID"] = "123456"
      ENV["GOOGLE_ANALYTICS_CREDENTIALS_JSON"] = nil
      allow(described_class::CREDENTIALS_PATH).to receive(:exist?).and_return(false)

      expect(described_class.configured?).to be false
    end

    it "is true when the property id and the credentials file are present" do
      ENV["GOOGLE_ANALYTICS_PROPERTY_ID"] = "123456"
      ENV["GOOGLE_ANALYTICS_CREDENTIALS_JSON"] = nil
      allow(described_class::CREDENTIALS_PATH).to receive(:exist?).and_return(true)

      expect(described_class.configured?).to be true
    end

    it "is true when the property id and the credentials JSON env var are present, even without a file" do
      ENV["GOOGLE_ANALYTICS_PROPERTY_ID"] = "123456"
      ENV["GOOGLE_ANALYTICS_CREDENTIALS_JSON"] = '{"type": "service_account"}'
      allow(described_class::CREDENTIALS_PATH).to receive(:exist?).and_return(false)

      expect(described_class.configured?).to be true
    end

    it "prefers the JSON env var over the file when both are present" do
      ENV["GOOGLE_ANALYTICS_PROPERTY_ID"] = "123456"
      ENV["GOOGLE_ANALYTICS_CREDENTIALS_JSON"] = '{"type": "service_account"}'
      allow(described_class::CREDENTIALS_PATH).to receive(:exist?).and_return(true)

      expect(described_class.credentials_source).to eq('{"type": "service_account"}')
    end
  end

  describe "#summary" do
    it "raises when Google Analytics is not configured" do
      allow(described_class).to receive(:configured?).and_return(false)

      expect { described_class.new.summary }.to raise_error(described_class::Error, /not configured/)
    end

    it "raises for a day range outside the allowed presets" do
      allow(described_class).to receive(:configured?).and_return(true)

      expect { described_class.new.summary(days: 15) }.to raise_error(described_class::Error, /Unsupported day range/)
    end
  end

  describe "ALLOWED_DAY_RANGES" do
    it "is exactly the three presets the admin UI offers" do
      expect(described_class::ALLOWED_DAY_RANGES).to eq([ 7, 30, 90 ])
    end
  end
end
