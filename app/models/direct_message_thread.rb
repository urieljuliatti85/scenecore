# A Core Member's private message thread with a band (docs/band-admin.md
# §16). One thread per Core Member per band — messages within it are the
# ongoing conversation, not a generic public feed.
class DirectMessageThread < ApplicationRecord
  belongs_to :band
  belongs_to :user
  has_many :direct_messages, dependent: :destroy

  enum :status, { open: "open", archived: "archived", blocked: "blocked" },
       default: :open, validate: true

  validates :user_id, uniqueness: { scope: :band_id }

  # Being blocked stops the Core Member from sending new messages, but the
  # band can still read/reply to the existing history — see
  # DirectMessagePolicy for who can still post.
  def messageable_by_member?
    !blocked?
  end
end
