class CreateCoreSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :core_sessions do |t|
      t.references :band, null: false, foreign_key: true
      t.string :title, null: false
      t.string :session_type, null: false
      t.datetime :starts_at, null: false
      t.integer :capacity
      t.text :description
      t.string :status, default: "draft", null: false

      t.timestamps
    end

    add_check_constraint :core_sessions,
      "session_type IN ('video', 'audio', 'qa', 'listening_party', 'meet_greet')",
      name: "core_sessions_session_type_check"
    add_check_constraint :core_sessions, "status IN ('draft', 'published')", name: "core_sessions_status_check"
    add_check_constraint :core_sessions, "capacity IS NULL OR capacity > 0", name: "core_sessions_capacity_check"
  end
end
