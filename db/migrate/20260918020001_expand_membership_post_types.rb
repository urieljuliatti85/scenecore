class ExpandMembershipPostTypes < ActiveRecord::Migration[8.1]
  POST_TYPES = %w[
    announcement
    demo
    alternative_version
    composition_journal
    production_journal
    rehearsal_recording
    exclusive_video
    exclusive_stream
    rare_archive
  ].freeze

  def up
    remove_check_constraint :posts, name: "posts_post_type_check"
    add_check_constraint :posts, "post_type IN (#{POST_TYPES.map { |type| "'#{type}'" }.join(', ')})", name: "posts_post_type_check"
  end

  def down
    remove_check_constraint :posts, name: "posts_post_type_check"
    add_check_constraint :posts, "post_type IN ('announcement', 'composition_journal', 'rehearsal_recording')", name: "posts_post_type_check"
  end
end
