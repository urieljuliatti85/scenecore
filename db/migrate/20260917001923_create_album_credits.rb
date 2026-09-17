class CreateAlbumCredits < ActiveRecord::Migration[8.1]
  def change
    create_table :album_credits do |t|
      t.references :album, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :album_credits, [ :album_id, :user_id ], unique: true
  end
end
