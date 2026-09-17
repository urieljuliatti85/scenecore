require "rails_helper"

RSpec.describe Country do
  it "names a code" do
    expect(described_class.name_for("BR")).to eq("Brazil")
  end

  it "accepts a code however it is cased or padded" do
    expect(described_class.name_for(" br ")).to eq("Brazil")
    expect(described_class).to be_valid("br")
  end

  it "rejects something that is not a country" do
    expect(described_class).not_to be_valid("ZZ")
    expect(described_class.name_for("ZZ")).to be_nil
  end

  it "rejects a blank code" do
    expect(described_class).not_to be_valid(nil)
    expect(described_class).not_to be_valid("")
  end

  # Band#country_code and shipping zones match on this format, so the table
  # must not drift away from it.
  it "holds only two-letter upper-case codes" do
    expect(described_class::CODES).to all(match(/\A[A-Z]{2}\z/))
  end

  it "covers the countries the app already assumes" do
    expect(described_class::CODES).to include("BR", "US", "GB", "PT", "JP")
  end

  describe ".options" do
    it "pairs a name with its code for a select" do
      expect(described_class.options).to include([ "Brazil", "BR" ])
    end

    it "is ordered by name so the list reads in order" do
      names = described_class.options.map(&:first)

      expect(names).to eq(names.sort)
    end

    it "offers every country exactly once" do
      codes = described_class.options.map(&:last)

      expect(codes.size).to eq(described_class::CODES.size)
      expect(codes.uniq).to eq(codes)
    end
  end
end
