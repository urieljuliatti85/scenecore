class CreateCoreSessionRsvps < ActiveRecord::Migration[8.1]
  def change
    create_table :core_session_rsvps do |t|
      t.references :core_session, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :core_session_rsvps, [ :core_session_id, :user_id ], unique: true
  end
end
