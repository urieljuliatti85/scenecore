require "rails_helper"

# Mail used to go out from the generated placeholder addresses
# ("please-change-me-at-...@example.com" and "from@example.com"), which
# every provider rejects. Both now come from MAIL_FROM.
#
# The other half of this — production only attempting delivery once
# SMTP_ADDRESS is set, rather than raising against localhost:25 and turning a
# password reset into a 500 — lives in config/environments/production.rb and
# is verified by booting that environment, not from here.
RSpec.describe "Mail sender configuration" do
  it "addresses mail from a real sender, not the generated placeholder" do
    expect(Devise.mailer_sender).not_to include("please-change-me")
    expect(Devise.mailer_sender).not_to include("example.com")
  end

  it "sends application mail from the same sender as Devise" do
    expect(ApplicationMailer.default[:from]).to eq(Devise.mailer_sender)
  end
end
