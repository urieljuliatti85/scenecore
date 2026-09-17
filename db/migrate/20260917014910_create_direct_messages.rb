class CreateDirectMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :direct_messages do |t|
      t.references :direct_message_thread, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :sent_by_band, default: false, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_check_constraint :direct_messages, "char_length(body) > 0 AND char_length(body) <= 2000",
      name: "direct_messages_body_length_check"
  end
end
