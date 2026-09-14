class CreateAdminActionLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_action_logs do |t|
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.references :subject, polymorphic: true, null: false

      t.timestamps
    end
  end
end
