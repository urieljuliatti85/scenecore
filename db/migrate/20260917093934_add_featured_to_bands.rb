class AddFeaturedToBands < ActiveRecord::Migration[8.1]
  def change
    add_column :bands, :featured, :boolean, null: false, default: false

    # At most one featured band platform-wide: the home page hero renders
    # exactly one. A partial unique index, not a model validation, since
    # two concurrent feature requests could otherwise both pass a
    # Ruby-level check before either commits.
    add_index :bands, :featured, unique: true, where: "featured = true"
  end
end
