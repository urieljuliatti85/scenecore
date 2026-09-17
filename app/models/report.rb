# A fan/member flagging content for platform review (docs/band-admin.md
# §27). Distinct from a band moderating its own community day-to-day
# (docs/community.md §11) — this is the escalation path to the SceneCore
# Administrator for abuse, illegal content, or serious policy violations.
class Report < ApplicationRecord
  belongs_to :reporter, class_name: "User"
  belongs_to :reportable, polymorphic: true

  enum :status, { pending: "pending", resolved: "resolved", dismissed: "dismissed" },
       default: :pending, validate: true

  validates :reason, presence: true
end
