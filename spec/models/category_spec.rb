require "rails_helper"

RSpec.describe Category, type: :model do
  it "is valid with valid attributes" do
    expect(build(:category)).to be_valid
  end

  it "requires a name" do
    category = build(:category, name: nil)

    expect(category).not_to be_valid
  end

  it "generates a slug from the name on create" do
    category = create(:category, name: "Rock")

    expect(category.slug).to eq("rock")
  end

  it "generates a unique slug when names collide" do
    create(:category, name: "Rock")
    other = create(:category, name: "Rock")

    expect(other.slug).to eq("rock-2")
  end

  it "rejects a duplicate slug at the database level even if validation is bypassed" do
    create(:category, name: "Rock")
    duplicate = build(:category, name: "Other name")
    duplicate.slug = "rock"

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe "hierarchy" do
    it "is a root category when it has no parent" do
      category = build(:category, parent: nil)

      expect(category).to be_root
    end

    it "is not a root category when it has a parent" do
      category = create(:category, :with_parent)

      expect(category).not_to be_root
    end

    it "allows a root category as a parent" do
      root = create(:category)
      subcategory = build(:category, parent: root)

      expect(subcategory).to be_valid
    end

    it "rejects a subcategory as a parent (no more than two levels)" do
      root = create(:category)
      subcategory = create(:category, parent: root)
      grandchild = build(:category, parent: subcategory)

      expect(grandchild).not_to be_valid
      expect(grandchild.errors[:parent]).to be_present
    end

    it "prevents deleting a category that has subcategories" do
      root = create(:category)
      create(:category, parent: root)

      expect(root.destroy).to be false
      expect(root.errors[:base]).to be_present
      expect(Category.exists?(root.id)).to be true
    end
  end

  describe "bands" do
    it "nullifies its bands' category when destroyed" do
      category = create(:category)
      band = create(:band, category: category)

      category.destroy

      expect(band.reload.category).to be_nil
    end
  end
end
