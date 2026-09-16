require "rails_helper"

RSpec.describe Comment, type: :model do
  it "is valid with valid attributes" do
    expect(build(:comment)).to be_valid
  end

  it "requires a body" do
    comment = build(:comment, body: nil)

    expect(comment).not_to be_valid
  end

  it "requires a post" do
    comment = build(:comment, post: nil)

    expect(comment).not_to be_valid
  end

  it "requires a user" do
    comment = build(:comment, user: nil)

    expect(comment).not_to be_valid
  end

  it "is destroyed when its post is destroyed" do
    comment = create(:comment)
    post = comment.post

    post.destroy

    expect(Comment.exists?(comment.id)).to be false
  end
end
