class CreateDirectMessageThreads < ActiveRecord::Migration[8.1]
  def change
    create_table :direct_message_threads do |t|
      t.references :band, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status, default: "open", null: false

      t.timestamps
    end

    add_index :direct_message_threads, [ :band_id, :user_id ], unique: true
    add_check_constraint :direct_message_threads, "status IN ('open', 'archived', 'blocked')",
      name: "direct_message_threads_status_check"
  end
end
