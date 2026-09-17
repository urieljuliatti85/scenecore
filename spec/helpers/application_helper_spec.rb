require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#nav_pill_link" do
    it "renders a link with its label and path" do
      html = helper.nav_pill_link("Bands", "/bands", current: false)

      expect(html).to have_link("Bands", href: "/bands")
    end

    it "marks the current page for assistive technology" do
      current = helper.nav_pill_link("Bands", "/bands", current: true)
      other = helper.nav_pill_link("Bands", "/bands", current: false)

      expect(current).to include('aria-current="page"')
      expect(other).not_to include("aria-current")
    end

    it "tints the current item instead of filling it" do
      html = helper.nav_pill_link("Bands", "/bands", current: true)

      expect(html).to include("bg-yellow-400/10")
      expect(html).to include("text-yellow-300")
    end

    it "leaves the other items flat" do
      html = helper.nav_pill_link("Bands", "/bands", current: false)

      expect(html).to include("text-neutral-400")
      expect(html).to include("border-transparent")
    end

    it "renders an icon when one is given" do
      html = helper.nav_pill_link("Home", "/", current: false, icon: :home)

      expect(html).to include("<svg")
      expect(html).to include('aria-hidden="true"')
    end

    # The header renders several links without an icon (and the helper is
    # used elsewhere), so a missing icon must not raise or emit an empty tag.
    it "renders without an icon" do
      html = helper.nav_pill_link("Bands", "/bands", current: false)

      expect(html).not_to include("<svg")
      expect(html).to have_link("Bands", href: "/bands")
    end

    it "ignores an unknown icon rather than raising" do
      html = helper.nav_pill_link("Bands", "/bands", current: false, icon: :not_an_icon)

      expect(html).to have_link("Bands", href: "/bands")
      expect(html).not_to include("<svg")
    end
  end
end
