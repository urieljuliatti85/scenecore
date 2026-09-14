require "rails_helper"

RSpec.describe "Mobile navigation", type: :system do
  before do
    # window.resize_to is unreliable under --headless=new in CI containers
    # (no real window manager), so force the viewport via CDP instead —
    # this is deterministic regardless of headless mode. mobile: false
    # keeps normal mouse/click event dispatch (mobile: true switches to
    # touch emulation, which broke Devise form submission in this app).
    page.driver.browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width: 375, height: 800, deviceScaleFactor: 1, mobile: false
    )
  end

  after do
    # Reset the override so it doesn't leak into specs that reuse this
    # browser session/worker later in the same run.
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  end

  it "exposes Bands and auth links behind a menu button when signed out" do
    visit root_path

    within("#desktop-nav") do
      expect(page).to have_no_link("Bands", visible: :visible)
    end

    find("button[aria-label='Open menu']").click

    within("#mobile-menu-panel") do
      expect(page).to have_link("Bands")
      expect(page).to have_link("Sign in")
      expect(page).to have_link("Join Now")
    end
  end

  it "exposes Your bands, Profile, and Sign out behind the menu when signed in" do
    user = create(:user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    click_button "Log in"

    expect(page).to have_content("Signed in successfully")

    find("button[aria-label='Open menu']").click

    within("#mobile-menu-panel") do
      expect(page).to have_link("Your bands")
      expect(page).to have_link("Profile")
      expect(page).to have_button("Sign out")
      expect(page).to have_no_link("Admin")
    end
  end

  it "exposes Admin when signed in as a platform administrator" do
    admin = create(:user, :platform_admin)
    visit new_user_session_path
    fill_in "Email", with: admin.email
    fill_in "Password", with: admin.password
    click_button "Log in"

    expect(page).to have_content("Signed in successfully")

    find("button[aria-label='Open menu']").click

    within("#mobile-menu-panel") do
      expect(page).to have_link("Admin")
    end
  end
end
