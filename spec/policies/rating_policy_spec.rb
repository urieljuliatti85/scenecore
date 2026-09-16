require "rails_helper"

RSpec.describe RatingPolicy do
  subject { described_class.new(user, rating) }

  describe "#upsert?" do
    context "when the album is published and the user is signed in" do
      let(:user) { create(:user) }
      let(:rating) { build(:rating, album: create(:album, :published), user: user) }

      it { is_expected.to be_upsert }
    end

    context "when the album is still a draft" do
      let(:user) { create(:user) }
      let(:rating) { build(:rating, album: create(:album), user: user) }

      it { is_expected.not_to be_upsert }
    end

    context "when the user is anonymous" do
      let(:user) { nil }
      let(:rating) { build(:rating, album: create(:album, :published)) }

      it { is_expected.not_to be_upsert }
    end
  end
end
