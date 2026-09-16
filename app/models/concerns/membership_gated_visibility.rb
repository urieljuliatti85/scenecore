# Shared by any band-owned record whose access depends on the viewer's
# relationship with the band: public, followers (free, via Follow), or a
# paid Membership level. See Post and Poll.
#
# Ordered low to high: each level also sees everything below it.
# "followers" sits below the paid Membership levels since it's the free
# relationship — a Fan/Supporter/Core Member is not assumed to also
# follow the band, but still outranks a plain follower.
module MembershipGatedVisibility
  extend ActiveSupport::Concern

  VISIBILITY_LEVELS = %w[public followers fan supporter core_member].freeze

  included do
    enum :visibility, VISIBILITY_LEVELS.index_with(&:itself),
         default: :public, validate: true, prefix: true
  end

  def visible_to?(user, following: nil)
    return true if visibility_public?
    return false if user.nil?

    membership = band.memberships.find_by(user: user)
    following = band.follows.exists?(user: user) if following.nil?
    return true if visibility_followers? && (following || membership&.grants_access?)

    membership.present? && membership.can_access?(visibility)
  end
end
