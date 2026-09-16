class CreatePollVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :poll_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :poll_option, null: false, foreign_key: true

      t.timestamps
    end

    add_index :poll_votes, [ :user_id, :poll_option_id ], unique: true
  end
end
