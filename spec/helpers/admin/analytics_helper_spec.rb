require "rails_helper"

RSpec.describe Admin::AnalyticsHelper, type: :helper do
  describe "#analytics_duration" do
    it "shows plain seconds under a minute" do
      expect(helper.analytics_duration(47)).to eq("47 s")
    end

    it "shows minutes and seconds at a minute or more" do
      expect(helper.analytics_duration(85)).to eq("1m 25s")
      expect(helper.analytics_duration(3_600)).to eq("60m 0s")
    end

    it "treats a missing duration as zero" do
      expect(helper.analytics_duration(nil)).to eq("0 s")
    end
  end

  describe "#analytics_percentage" do
    it "renders a GA4 fraction as a percentage" do
      expect(helper.analytics_percentage(0.57)).to eq("57%")
    end

    it "treats a missing rate as zero" do
      expect(helper.analytics_percentage(nil)).to eq("0%")
    end
  end
end
