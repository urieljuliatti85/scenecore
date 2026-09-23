class CreateBandVerificationRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :band_verification_requests do |t|
      t.references :band, null: false, foreign_key: true
      t.string :email, null: false
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    # Mirrors band_admin_requests' partial-unique-index shape: at most one
    # open (not yet decided) verification request per band at a time, so a
    # band cannot stack duplicate submissions while one is already pending
    # or awaiting the emailed click.
    add_index :band_verification_requests, :band_id,
              unique: true,
              where: "status IN ('pending', 'email_sent')",
              name: "index_band_verification_requests_on_band_open"

    add_check_constraint :band_verification_requests,
                          "status IN ('pending', 'email_sent', 'verified', 'rejected')",
                          name: "band_verification_requests_status_check"
  end
end
