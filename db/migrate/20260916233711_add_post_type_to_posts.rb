class AddPostTypeToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :post_type, :string, default: "announcement", null: false

    add_check_constraint :posts, "post_type IN ('announcement', 'composition_journal')", name: "posts_post_type_check"
  end
end
