require "rails_helper"

RSpec.describe UserPolicy do
  subject { described_class.new(user, other_user) }

  let(:other_user) { create(:user) }

  %i[index? edit? update? destroy?].each do |action|
    describe "##{action}" do
      context "when user is a platform administrator" do
        let(:user) { create(:user, :platform_admin) }

        it { expect(subject.public_send(action)).to be true }
      end

      context "when user is a regular user" do
        let(:user) { create(:user) }

        it { expect(subject.public_send(action)).to be false }
      end

      context "when user is anonymous" do
        let(:user) { nil }

        it { expect(subject.public_send(action)).to be false }
      end
    end
  end
end
