require "rails_helper"

RSpec.describe "Merch Discounts", type: :request do
  describe "PATCH /bands/:band_id/merch_discounts" do
    it "creates discounts for a band administrator" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      patch band_merch_discounts_path(band), params: { merch_discounts: { fan: "0", supporter: "10", core_member: "20" } }

      expect(response).to redirect_to(edit_band_path(band))
      expect(band.merch_discounts.find_by(level: :fan).percentage).to eq(0)
      expect(band.merch_discounts.find_by(level: :supporter).percentage).to eq(10)
      expect(band.merch_discounts.find_by(level: :core_member).percentage).to eq(20)
    end

    it "updates an existing discount instead of creating a duplicate" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      create(:merch_discount, band: band, level: :supporter, percentage: 5)
      sign_in user

      expect {
        patch band_merch_discounts_path(band), params: { merch_discounts: { supporter: "15" } }
      }.not_to change(MerchDiscount, :count)

      expect(band.merch_discounts.find_by(level: :supporter).percentage).to eq(15)
    end

    it "rejects a percentage over 100" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, :administrator, band: band, user: user)
      sign_in user

      patch band_merch_discounts_path(band), params: { merch_discounts: { fan: "150" } }

      expect(response).to redirect_to(edit_band_path(band))
      expect(band.merch_discounts.find_by(level: :fan)).to be_nil
    end

    it "prevents a plain band member from updating discounts" do
      user = create(:user)
      band = create(:band)
      create(:band_membership, band: band, user: user)
      sign_in user

      patch band_merch_discounts_path(band), params: { merch_discounts: { fan: "10" } }

      expect(response).to redirect_to(root_path)
      expect(band.merch_discounts.find_by(level: :fan)).to be_nil
    end

    it "prevents an administrator of another band from updating discounts" do
      band = create(:band)
      outsider = create(:user)
      create(:band_membership, :administrator, band: create(:band), user: outsider)
      sign_in outsider

      patch band_merch_discounts_path(band), params: { merch_discounts: { fan: "10" } }

      expect(response).to redirect_to(root_path)
      expect(band.merch_discounts.find_by(level: :fan)).to be_nil
    end

    it "requires authentication" do
      band = create(:band)

      patch band_merch_discounts_path(band), params: { merch_discounts: { fan: "10" } }

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
