class CreatePolls < ActiveRecord::Migration[8.1]
  def change
    create_table :polls do |t|
      t.references :band, null: false, foreign_key: true
      t.string :question, null: false
      t.string :status, null: false, default: "draft"
      t.string :visibility, null: false, default: "public"
      t.boolean :allow_multiple_choices, null: false, default: false
      t.boolean :allow_vote_change, null: false, default: false
      t.datetime :opens_at
      t.datetime :closes_at

      t.timestamps
    end

    add_index :polls, [ :band_id, :status ]

    add_check_constraint :polls, "status IN ('draft', 'published')", name: "polls_status_check"
    add_check_constraint :polls, "visibility IN ('public', 'followers', 'fan', 'supporter', 'core_member')", name: "polls_visibility_check"
  end
end
