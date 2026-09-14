class AdminActionLog < ApplicationRecord
  belongs_to :actor, class_name: "User"
  belongs_to :subject, polymorphic: true

  validates :action, presence: true
end
