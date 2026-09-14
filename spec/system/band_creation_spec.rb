require "rails_helper"

RSpec.describe "Band creation", type: :system do
  it "lets a signed-up user create a band that starts out pending approval" do
    user = create(:user, name: "Alice")

    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: user.password
    click_button "Log in"
    expect(page).to have_content("Signed in successfully")

    visit new_band_path
    fill_in "band_name", with: "The Testers"
    click_button "Create Band"

    expect(page).to have_content("The Testers")
    expect(page).to have_content(/pending/i)
  end
end
