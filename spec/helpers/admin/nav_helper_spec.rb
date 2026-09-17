require "rails_helper"

RSpec.describe Admin::NavHelper, type: :helper do
  describe "#admin_nav_link" do
    it "renders a link with its label and path" do
      html = helper.admin_nav_link("Bands", "/admin/bands", current: false, section: :bands)

      expect(html).to have_link("Bands", href: "/admin/bands")
    end

    it "tints an idle item's dot with the section accent" do
      html = helper.admin_nav_link("Bands", "/admin/bands", current: false, section: :bands)

      expect(html).to include("bg-emerald-400")
      expect(html).to include("text-neutral-300")
    end

    it "gives each section a different accent" do
      bands = helper.admin_nav_link("Bands", "/admin/bands", current: false, section: :bands)
      users = helper.admin_nav_link("Users", "/admin/users", current: false, section: :users)

      expect(bands).to include("bg-emerald-400")
      expect(users).to include("bg-sky-400")
    end

    it "moves the accent to the background when the item is current" do
      html = helper.admin_nav_link("Bands", "/admin/bands", current: true, section: :bands)

      expect(html).to include("bg-emerald-400 text-black")
    end

    it "keeps the current item's dot legible against its accent background" do
      html = helper.admin_nav_link("Bands", "/admin/bands", current: true, section: :bands)

      expect(html).to include("bg-black/40")
    end

    it "hides the decorative dot from assistive technology" do
      html = helper.admin_nav_link("Bands", "/admin/bands", current: false, section: :bands)

      expect(html).to include('aria-hidden="true"')
    end

    it "falls back to the neutral accent when no section is given" do
      html = helper.admin_nav_link("Somewhere", "/admin/somewhere", current: true)

      expect(html).to include("bg-white text-black")
    end
  end
end
