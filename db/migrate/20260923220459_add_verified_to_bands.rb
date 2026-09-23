class AddVerifiedToBands < ActiveRecord::Migration[8.1]
  def change
    # A safe default (false for every existing row) means this can be a
    # plain add_column, unlike the nullable-then-backfill dance a
    # not-safely-defaultable null: false column would need (CLAUDE.md).
    add_column :bands, :verified, :boolean, null: false, default: false
  end
end
