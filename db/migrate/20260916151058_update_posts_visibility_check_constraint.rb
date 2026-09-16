class UpdatePostsVisibilityCheckConstraint < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :posts, name: "posts_visibility_check"
    add_check_constraint :posts, "visibility IN ('public', 'followers', 'fan', 'supporter', 'core_member')", name: "posts_visibility_check"
  end

  def down
    remove_check_constraint :posts, name: "posts_visibility_check"
    add_check_constraint :posts, "visibility IN ('public', 'followers', 'subscribers')", name: "posts_visibility_check"
  end
end
