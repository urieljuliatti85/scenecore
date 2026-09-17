class AddEarlyAccessToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :early_access_level, :string
    add_column :posts, :early_access_until, :datetime

    add_check_constraint :posts,
      "early_access_level IS NULL OR early_access_level IN ('fan', 'supporter', 'core_member')",
      name: "posts_early_access_level_check"
  end
end
