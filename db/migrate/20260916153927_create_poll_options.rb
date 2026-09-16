class CreatePollOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :poll_options do |t|
      t.references :poll, null: false, foreign_key: true
      t.string :label, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :poll_options, [ :poll_id, :position ]
  end
end
