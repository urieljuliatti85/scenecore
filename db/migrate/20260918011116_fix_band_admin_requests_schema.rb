# The band_admin_requests migration (20260918000640) was rewritten after
# it had already run in production — production applied it with the old
# shape (belongs_to :band_membership), then the file was edited locally
# to belongs_to :user/:band before merging. Rails never re-runs an
# applied migration, so production was left with a table that doesn't
# match what the current model/schema expect, causing
# PG::UndefinedColumn on band_admin_requests.band_id in production
# (see the 500 on GET /:slug for any band).
#
# The table is new and had no real usage (feature just shipped), so this
# recreates it from scratch to the current shape rather than trying to
# reconcile columns in place. Idempotent against an environment that
# already has the correct shape (e.g. a fresh `db:schema:load`, or a dev
# database that ran the corrected 20260918000640 directly) by checking
# the actual columns before doing anything.
class FixBandAdminRequestsSchema < ActiveRecord::Migration[8.1]
  def up
    return if column_exists?(:band_admin_requests, :user_id) && column_exists?(:band_admin_requests, :band_id)

    drop_table :band_admin_requests

    create_table :band_admin_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :band, null: false, foreign_key: true
      t.string :status, default: "pending", null: false

      t.timestamps
    end

    add_check_constraint :band_admin_requests,
      "status IN ('pending', 'approved', 'rejected', 'revoked')",
      name: "band_admin_requests_status_check"

    add_index :band_admin_requests, [ :user_id, :band_id ],
      unique: true, where: "status = 'pending'",
      name: "index_band_admin_requests_on_pending_user_and_band"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
