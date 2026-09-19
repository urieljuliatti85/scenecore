require "rails_helper"

RSpec.describe Admin::NavHelper, type: :helper do
  describe "#admin_nav_link" do
    it "renders a link with its label and path" do
      html = helper.admin_nav_link("Bands", "/admin/bands", current: false, section: :bands)

      expect(html).to have_link("Bands", href: "/admin/bands")
    end

    it "renders the section icon beside the label" do
      html = helper.admin_nav_link("Bands", "/admin/bands", current: false, section: :bands)

      expect(html).to include("<svg")
      expect(html).to include("group-hover:text-yellow-300")
    end

    it "keeps an idle item quiet until hover" do
      html = helper.admin_nav_link("Bands", "/admin/bands", current: false, section: :bands)

      expect(html).to include("border-transparent")
      expect(html).to include("text-neutral-500")
    end

    it "uses the shared yellow treatment when the item is current" do
      html = helper.admin_nav_link("Bands", "/admin/bands", current: true, section: :bands)

      expect(html).to include("border-yellow-400")
      expect(html).to include("bg-[#393939]")
      expect(html).to include("text-white")
      expect(html).to include('aria-current="page"')
    end

    it "uses the active icon tone on the current item" do
      html = helper.admin_nav_link("Bands", "/admin/bands", current: true, section: :bands)

      expect(html).to include("text-yellow-400")
    end

    it "hides the decorative icon from assistive technology" do
      html = helper.admin_nav_link("Bands", "/admin/bands", current: false, section: :bands)

      expect(html).to include('aria-hidden="true"')
    end

    it "falls back to the dashboard icon when no section is given" do
      html = helper.admin_nav_link("Somewhere", "/admin/somewhere", current: true)

      expect(html).to include("<rect")
      expect(html).to include("bg-[#393939]")
    end
  end
end
