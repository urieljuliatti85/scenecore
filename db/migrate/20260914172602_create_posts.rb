class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.references :band, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.string :status, null: false, default: "draft"
      t.string :visibility, null: false, default: "public"

      t.timestamps
    end

    add_index :posts, [ :band_id, :status, :visibility ]
  end
end
