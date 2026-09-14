require "rails_helper"

RSpec.describe "Band member invitation", type: :system do
  # KNOWN FLAKE, not fixed — documenting honestly instead of claiming a fix
  # that hasn't held up. Symptom: `click_button "Add member"` below
  # sometimes does nothing — no exception, no console error, and
  # log/test.log shows the preceding GET .../members/new as the last
  # request; the POST it should trigger never arrives at the server. Every
  # failure screenshot shows the exact same thing: the unstyled form, still
  # showing the correctly-selected value, submit button untouched.
  #
  # Confirmed properties of the flake (verified with real instrumentation,
  # not just log-reading, across many local runs with CI=true):
  #   - Only reproduces when the full `spec/system` suite runs together —
  #     never when this spec file runs alone, however many times repeated.
  #   - When it does trigger, it does not recover: polling
  #     `page.current_url` for 5+ seconds after the click shows no change.
  #     It is a dropped event, not merely a slow one.
  #   - JS-level instrumentation (click/submit listeners attached to the
  #     button/form right before the click) never observed the listener
  #     fire on a failing run — consistent with the click never reaching
  #     the element, not with it reaching the element and something later
  #     failing silently.
  #
  # Hypotheses tried and ruled out by direct evidence, not just "it still
  # failed once more":
  #   1. Capybara.default_max_wait_time too low — raising it from 5s to
  #      10s did not reduce the failure rate at all (it's a dropped event,
  #      not a slow one, so more waiting can't help).
  #   2. GitHub Actions' 64MB /dev/shm cap corrupting Chrome's renderer IPC
  #      — added --disable-dev-shm-usage; real CI runs still failed with it
  #      in place (see CI run 34849947131), so kept as cheap insurance but
  #      not treated as a fix.
  #   3. Turbo intercepting the click/submit — tried disabling
  #      `Turbo.session.drive` both after each Capybara `visit` and via a
  #      CDP script injected before any page script runs (so it can't lose
  #      the race with Turbo's own boot). Neither reduced the failure rate;
  #      the second was verified locally to still fail at a similar rate.
  #   4. The <select> element retaining focus/its native popup capturing
  #      the very next click — `find_field("User").send_keys(:tab)` below
  #      blurs it before the click. This looked very promising in a first
  #      round of local testing (42/42 clean) but then failed 14/20 in a
  #      larger stress run, so it is NOT a confirmed fix either — it's left
  #      in place because it's a plausible partial mitigation and provably
  #      doesn't hurt, not because it solved this.
  #
  # Net honest status: root cause is still unknown. The one solid fact is
  # that this only shows up under whatever process/timing state exists when
  # multiple system specs run in the same suite — something about shared
  # state or resource contention across specs, not a bug in any single
  # spec's steps. Do not mark this pending/skipped — the system-test CI job
  # retries once and keeps screenshots/log as an artifact from the first
  # attempt specifically so this stays investigable by whoever picks it up
  # next.
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
    expect(page).to have_select("User", selected: new_member.email)
    # Blurs the select before submitting — see the class-level comment
    # above. Plausible partial mitigation, not a confirmed fix.
    find_field("User").send_keys(:tab)
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
