class CreateBandAdminRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :band_admin_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :band, null: false, foreign_key: true
      t.string :status, default: "pending", null: false

      t.timestamps
    end

    add_check_constraint :band_admin_requests,
      "status IN ('pending', 'approved', 'rejected', 'revoked')",
      name: "band_admin_requests_status_check"

    # One open request per user per band: they can't stack a second
    # request for the same band while the first is still awaiting a
    # decision, enforced here rather than only in the model so it holds
    # under concurrent requests.
    add_index :band_admin_requests, [ :user_id, :band_id ],
      unique: true, where: "status = 'pending'",
      name: "index_band_admin_requests_on_pending_user_and_band"
  end
end
