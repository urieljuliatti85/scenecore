require "rails_helper"

RSpec.describe "Contact messages", type: :request do
  # The limiter keeps counters in a module-level store, so one example's
  # requests would otherwise count against the next one's.
  before { ContactMessagesController::RATE_LIMIT_STORE.clear }

  let(:valid_params) do
    { contact_message: { name: "Ana", email: "ana@example.com", band: "Farscape", message: "Hello there" } }
  end

  describe "GET /contact" do
    it "is reachable without signing in" do
      get contact_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Get in touch with the SceneCore team")
    end

    it "links to Support" do
      get contact_path

      expect(response.body).to include(support_path)
    end
  end

  describe "POST /contact" do
    it "stores the message and redirects" do
      expect { post contact_path, params: valid_params }
        .to change(ContactMessage, :count).by(1)

      message = ContactMessage.last
      expect(message.name).to eq("Ana")
      expect(message.email).to eq("ana@example.com")
      expect(message.band).to eq("Farscape")
      expect(message.message).to eq("Hello there")
      expect(response).to redirect_to(contact_path)
    end

    it "accepts a message without a band" do
      params = valid_params.deep_merge(contact_message: { band: "" })

      expect { post contact_path, params: params }.to change(ContactMessage, :count).by(1)
      expect(ContactMessage.last.band).to eq("")
    end

    it "rejects a message with missing fields" do
      expect {
        post contact_path, params: { contact_message: { name: "", email: "", message: "" } }
      }.not_to change(ContactMessage, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a malformed email" do
      params = valid_params.deep_merge(contact_message: { email: "not-an-email" })

      expect { post contact_path, params: params }.not_to change(ContactMessage, :count)
      expect(response.body).to include("must be a valid email address")
    end

    it "emails the message when a recipient is configured" do
      allow(ContactMailer).to receive(:recipient).and_return("team@example.com")

      expect { post contact_path, params: valid_params }
        .to have_enqueued_mail(ContactMailer, :new_message)
    end

    it "still stores the message when no recipient is configured" do
      allow(ContactMailer).to receive(:recipient).and_return(nil)

      expect { post contact_path, params: valid_params }
        .to change(ContactMessage, :count).by(1)
      expect(response).to redirect_to(contact_path)
    end

    # The message is already saved at this point, so a mail failure must
    # not lose it or show the sender an error for something that arrived.
    it "keeps the message when delivery raises" do
      allow(ContactMailer).to receive(:recipient).and_return("team@example.com")
      allow(ContactMailer).to receive(:new_message).and_raise(StandardError, "smtp down")

      expect { post contact_path, params: valid_params }
        .to change(ContactMessage, :count).by(1)
      expect(response).to redirect_to(contact_path)
      expect(flash[:notice]).to match(/has been sent/)
    end

    it "rate limits repeated submissions" do
      6.times { post contact_path, params: valid_params }

      expect(ContactMessage.count).to eq(5)
      expect(flash[:alert]).to match(/Too many messages/)
    end
  end
end
