module AttachmentVisibility
  module_function

  def visible?(record, user:)
    band_member?(record, user) || publicly_visible?(record, user)
  end

  def band_member?(record, user)
    return false if user.nil?

    band_for(record)&.band_memberships&.exists?(user_id: user.id) || false
  end

  def publicly_visible?(record, user)
    case record
    when Band
      record.approved?
    when Album
      record.published? && record.band.approved?
    when Post
      record.published? && record.band.approved? && post_visibility_allowed?(record, user)
    else
      false
    end
  end

  def post_visibility_allowed?(post, user)
    return true if post.visibility_public?
    return false unless post.visibility_followers?

    user.present? && post.band.follows.exists?(user: user)
  end

  def band_for(record)
    case record
    when Band
      record
    when Album, Post
      record.band
    end
  end
end
