require "rails_helper"

RSpec.describe ProductPolicy do
  let(:band) { create(:band) }
  let(:product) { create(:product, band: band) }
  let(:actions) { %i[show? create? update? destroy? publish? unpublish?] }

  describe "Band Admin authorization" do
    it "allows an administrator of the product's band" do
      user = create(:user)
      create(:band_membership, :administrator, band: band, user: user)
      policy = described_class.new(user, product)

      actions.each { |action| expect(policy.public_send(action)).to be(true) }
    end

    it "does not allow a plain band member" do
      user = create(:user)
      create(:band_membership, band: band, user: user)
      policy = described_class.new(user, product)

      actions.each { |action| expect(policy.public_send(action)).to be(false) }
    end

    it "does not allow an administrator of another band" do
      user = create(:user)
      create(:band_membership, :administrator, band: create(:band), user: user)
      policy = described_class.new(user, product)

      actions.each { |action| expect(policy.public_send(action)).to be(false) }
    end

    it "allows a platform administrator" do
      user = create(:user, :platform_admin)
      policy = described_class.new(user, product)

      actions.each { |action| expect(policy.public_send(action)).to be(true) }
    end
  end
end
