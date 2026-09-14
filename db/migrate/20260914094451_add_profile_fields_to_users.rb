class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string, null: false, default: ""
    add_column :users, :platform_admin, :boolean, null: false, default: false
    change_column_default :users, :name, from: "", to: nil
  end
end
