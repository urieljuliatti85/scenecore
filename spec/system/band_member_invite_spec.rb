require "rails_helper"

RSpec.describe "Band member invitation", type: :system do
  # Known CI-only flake. Three spec-level attempts didn't fix it (longer
  # Capybara wait, waiting for the flash notice, waiting for the select's
  # change event to settle) — across CI runs, log/test.log showed a
  # *different* click silently failing to reach the server each time, which
  # ruled out a bug in one specific step of this spec.
  #
  # Current hypothesis (spec/rails_helper.rb): GitHub Actions containers cap
  # /dev/shm at 64MB, and Chrome uses /dev/shm for its shared renderer
  # memory by default; under memory pressure this is a documented cause of
  # silently dropped input events with no error anywhere, which matches
  # this symptom exactly. Added --disable-dev-shm-usage (moves Chrome's
  # shared memory to /tmp) to the CI driver. Passed locally with CI=true,
  # which proves nothing on its own since this has never failed locally —
  # real signal is whether it holds up over the next few real CI runs.
  #
  # Do not mark this pending/skipped if it still flakes — the system-test
  # CI job retries once and keeps screenshots/log as an artifact from the
  # first attempt specifically so this stays investigable.
  it "lets an administrator add a member who can see the band but not manage its members" do
    admin = create(:user, name: "Alice")
    new_member = create(:user, name: "Bob", email: "bob@example.com")
    band = create(:band, name: "The Testers")
    create(:band_membership, :administrator, band: band, user: admin)

    visit new_user_session_path
    fill_in "user_email", with: admin.email
    fill_in "user_password", with: admin.password
    click_button "Log in"
    expect(page).to have_content("Signed in successfully")

    visit band_band_memberships_path(band)
    click_link "Add member"
    expect(page).to have_button("Add member")
    select new_member.email, from: "User"
    # Confirm the DOM has actually caught up with the selection before
    # clicking submit — on the CI runner's headless Chrome, clicking submit
    # immediately after `select` sometimes fires before the browser has
    # finished processing the select's change event, and the click is lost.
    expect(page).to have_select("User", selected: new_member.email)
    click_button "Add member"

    expect(page).to have_content("Member added.")
    expect(page).to have_content("Bob")

    Capybara.reset_sessions!
    visit new_user_session_path
    fill_in "user_email", with: new_member.email
    fill_in "user_password", with: new_member.password
    click_button "Log in"
    expect(page).to have_content("Signed in successfully")

    visit band_path(band)

    expect(page).to have_content("The Testers")
    expect(page).not_to have_link("Members")
  end
end
