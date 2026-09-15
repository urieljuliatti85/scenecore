class AddEnumCheckConstraints < ActiveRecord::Migration[8.1]
  # Each of these columns backs an Active Record enum, but is a plain string
  # in Postgres — the allowed values were only enforced in the models. Three
  # `update_all` calls in AlbumsController/Admin::AlbumsController write
  # `status` directly, bypassing those validations entirely.
  def change
    add_check_constraint :bands, "status IN ('pending', 'approved', 'rejected', 'suspended')", name: "bands_status_check"
    add_check_constraint :band_memberships, "role IN ('member', 'administrator')", name: "band_memberships_role_check"
    add_check_constraint :albums, "status IN ('draft', 'published')", name: "albums_status_check"
    add_check_constraint :tracks, "status IN ('draft', 'published')", name: "tracks_status_check"
    add_check_constraint :posts, "status IN ('draft', 'published')", name: "posts_status_check"
    add_check_constraint :posts, "visibility IN ('public', 'followers', 'subscribers')", name: "posts_visibility_check"
  end
end
