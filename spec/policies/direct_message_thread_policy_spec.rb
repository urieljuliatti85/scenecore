require "rails_helper"

RSpec.describe DirectMessageThreadPolicy do
  let(:band) { create(:band) }
  let(:owner) { create(:user) }
  let(:thread) { create(:direct_message_thread, band: band, user: owner) }

  describe "#show?" do
    subject { described_class.new(user, thread) }

    it "is true for a band member" do
      user = create(:user)
      create(:band_membership, band: band, user: user)

      expect(described_class.new(user, thread).show?).to be true
    end

    it "is true for the thread's owner" do
      expect(described_class.new(owner, thread).show?).to be true
    end

    it "is false for an unrelated user" do
      expect(described_class.new(create(:user), thread).show?).to be false
    end

    it "is false for a member of a different band" do
      outsider = create(:user)
      create(:band_membership, band: create(:band), user: outsider)

      expect(described_class.new(outsider, thread).show?).to be false
    end

    it "is true for a platform administrator, for moderation triage" do
      expect(described_class.new(create(:user, :platform_admin), thread).show?).to be true
    end
  end

  describe "#create_message?" do
    it "is true for a band member regardless of thread status" do
      user = create(:user)
      create(:band_membership, band: band, user: user)
      blocked_thread = create(:direct_message_thread, :blocked, band: band, user: owner)

      expect(described_class.new(user, blocked_thread).create_message?).to be true
    end

    it "is true for the owner when the thread is open" do
      expect(described_class.new(owner, thread).create_message?).to be true
    end

    it "is true for the owner when the thread is archived" do
      archived_thread = create(:direct_message_thread, :archived, band: band, user: owner)

      expect(described_class.new(owner, archived_thread).create_message?).to be true
    end

    it "is false for the owner when the thread is blocked" do
      blocked_thread = create(:direct_message_thread, :blocked, band: band, user: owner)

      expect(described_class.new(owner, blocked_thread).create_message?).to be false
    end

    it "is false for an unrelated user" do
      expect(described_class.new(create(:user), thread).create_message?).to be false
    end

    it "is false for an anonymous visitor" do
      expect(described_class.new(nil, thread).create_message?).to be false
    end
  end

  %i[archive? block? unblock?].each do |action|
    describe "##{action}" do
      it "is true for a band member" do
        user = create(:user)
        create(:band_membership, band: band, user: user)

        expect(described_class.new(user, thread).public_send(action)).to be true
      end

      it "is false for the thread's owner" do
        expect(described_class.new(owner, thread).public_send(action)).to be false
      end

      it "is false for an unrelated user" do
        expect(described_class.new(create(:user), thread).public_send(action)).to be false
      end

      # #block? is the audited platform-moderation path (blocking a fan
      # abusing a band's DMs, logged by the controller); archiving and
      # unblocking are ordinary band housekeeping and need a membership.
      it "is #{action == :block? ? 'true' : 'false'} for a platform administrator, matching whether this is the moderation action" do
        expect(described_class.new(create(:user, :platform_admin), thread).public_send(action)).to be(action == :block?)
      end
    end
  end
end
