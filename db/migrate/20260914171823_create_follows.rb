class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.references :user, null: false, foreign_key: true
      t.references :band, null: false, foreign_key: true

      t.timestamps
    end

    add_index :follows, [ :user_id, :band_id ], unique: true
  end
end
