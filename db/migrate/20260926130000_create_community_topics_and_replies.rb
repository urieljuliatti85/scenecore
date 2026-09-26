class CreateCommunityTopicsAndReplies < ActiveRecord::Migration[8.1]
  def change
    create_table :community_topics do |t|
      t.references :band, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_index :community_topics, [ :band_id, :updated_at ]
    add_check_constraint :community_topics, "char_length(title) > 0", name: "community_topics_title_not_blank"
    add_check_constraint :community_topics, "char_length(body) > 0", name: "community_topics_body_not_blank"

    create_table :community_replies do |t|
      t.references :community_topic, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end

    add_index :community_replies, [ :community_topic_id, :created_at ]
    add_check_constraint :community_replies, "char_length(body) > 0", name: "community_replies_body_not_blank"
  end
end
