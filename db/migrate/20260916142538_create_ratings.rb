class CreateRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :album, null: false, foreign_key: true
      t.integer :score, null: false

      t.timestamps
    end

    add_index :ratings, [ :user_id, :album_id ], unique: true
    add_index :ratings, [ :album_id, :score ]

    add_check_constraint :ratings, "score BETWEEN 1 AND 5", name: "ratings_score_check"
  end
end
