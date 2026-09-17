class UpdatePostsPostTypeCheckConstraint < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :posts, name: "posts_post_type_check"
    add_check_constraint :posts, "post_type IN ('announcement', 'composition_journal', 'rehearsal_recording')", name: "posts_post_type_check"
  end

  def down
    remove_check_constraint :posts, name: "posts_post_type_check"
    add_check_constraint :posts, "post_type IN ('announcement', 'composition_journal')", name: "posts_post_type_check"
  end
end
