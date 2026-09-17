require "rails_helper"

RSpec.describe Admin::SectionHelper, type: :helper do
  describe "#admin_section_accent" do
    it "gives each section its own accent" do
      expect(helper.admin_section_accent(:bands, :text)).to eq("text-emerald-400")
      expect(helper.admin_section_accent(:users, :text)).to eq("text-sky-400")
      expect(helper.admin_section_accent(:memberships, :text)).to eq("text-violet-400")
      expect(helper.admin_section_accent(:reports, :text)).to eq("text-orange-400")
    end

    it "returns the requested variant" do
      expect(helper.admin_section_accent(:bands, :dot)).to eq("bg-emerald-400")
      expect(helper.admin_section_accent(:bands, :border)).to eq("border-emerald-500/40")
      expect(helper.admin_section_accent(:bands, :active)).to eq("bg-emerald-400 text-black")
    end

    it "accepts a string section" do
      expect(helper.admin_section_accent("bands", :text)).to eq("text-emerald-400")
    end

    it "falls back to the neutral accent for an unknown or missing section" do
      neutral = helper.admin_section_accent(:dashboard, :text)

      expect(helper.admin_section_accent(:not_a_section, :text)).to eq(neutral)
      expect(helper.admin_section_accent(nil, :text)).to eq(neutral)
    end

    it "raises on an unknown variant, so a typo fails loudly instead of rendering nothing" do
      expect { helper.admin_section_accent(:bands, :not_a_variant) }.to raise_error(KeyError)
    end

    it "spells out every accent as a literal Tailwind class" do
      # Tailwind v4 scans source text, so an interpolated class name would be
      # dropped from the build and the accent would silently disappear.
      described_class::ADMIN_SECTION_ACCENTS.each_value do |accents|
        accents.each_value do |classes|
          expect(classes).not_to include("#")
        end
      end
    end
  end
end
