class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reportable, polymorphic: true, null: false
      t.text :reason, null: false
      t.string :status, default: "pending", null: false

      t.timestamps
    end

    add_check_constraint :reports, "status IN ('pending', 'resolved', 'dismissed')", name: "reports_status_check"
    add_check_constraint :reports, "char_length(reason) > 0", name: "reports_reason_not_blank"
  end
end
